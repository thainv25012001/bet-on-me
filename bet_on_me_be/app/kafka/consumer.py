import asyncio
import json
import logging
import uuid
from datetime import datetime, timedelta

from aiokafka import AIOKafkaConsumer
from openai import APIError as OpenAIAPIError, RateLimitError as OpenAIRateLimitError
from sqlalchemy import select

from app.core.config import settings
from app.core.ws_manager import ws_manager
from app.db.session import AsyncSessionLocal
from app.models.goal_job import GoalJob
from app.models.goal import Goal
from app.models.plan import Plan
from app.models.task import Task
from app.repositories.subscription_repository import SubscriptionRepository
from app.schemas.goal import GoalGenerateRequest
from app.services.goal_service import _generate_tasks
from app.services.subscription_service import SubscriptionService
from app.utils import error_codes as ec
from app.utils.constants import GoalMode, JobStatus, PlanGeneratedBy

logger = logging.getLogger(__name__)


async def start_consumer() -> asyncio.Task:
    consumer = AIOKafkaConsumer(
        settings.KAFKA_GOAL_TOPIC,
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        group_id="goal_creation_workers",
        max_poll_records=10,          # prefetch = 10
        auto_offset_reset="earliest",
        enable_auto_commit=True,
    )
    await consumer.start()
    logger.info(
        "Kafka consumer started (topic=%s, prefetch=10)", settings.KAFKA_GOAL_TOPIC
    )
    return asyncio.create_task(_consume_loop(consumer))


async def _consume_loop(consumer: AIOKafkaConsumer) -> None:
    try:
        async for msg in consumer:
            try:
                await _process_message(msg)
            except Exception:
                logger.exception(
                    "Unhandled error processing message offset=%s", msg.offset
                )
    except asyncio.CancelledError:
        pass
    except Exception:
        logger.exception("Consumer loop crashed — stopping")
        raise
    finally:
        await consumer.stop()
        logger.info("Kafka consumer stopped")


async def _process_message(msg) -> None:
    data = json.loads(msg.value)
    job_id_str: str = data["job_id"]
    payload: dict = data["payload"]
    job_uuid = uuid.UUID(job_id_str)

    # ── Phase 1: mark as processing ──────────────────────────────────────────
    user_id: uuid.UUID | None = None
    async with AsyncSessionLocal() as db:
        job = await db.get(GoalJob, job_uuid)
        if job is None or job.status != JobStatus.PENDING:
            # Duplicate delivery or already handled — skip.
            return
        user_id = job.user_id
        job.status = JobStatus.PROCESSING
        job.started_at = datetime.utcnow()
        await db.commit()

    # ── Phase 2: call OpenAI (no DB session held during network I/O) ─────────
    try:
        gen_data = GoalGenerateRequest(**payload)

        # Load goal context (title, dates) and subscription cap.
        async with AsyncSessionLocal() as db_ctx:
            job_ctx = await db_ctx.get(GoalJob, job_uuid)
            goal_ctx = await db_ctx.get(Goal, job_ctx.goal_id)
            active_sub = await SubscriptionRepository(db_ctx).get_active_by_user(user_id)
            max_days = SubscriptionService.get_max_days_for_subscription(active_sub)
            goal_title = goal_ctx.title
            goal_start_date = goal_ctx.start_date
            goal_target_date = goal_ctx.target_date

        duration = (
            (goal_target_date - goal_start_date).days
            if gen_data.mode == GoalMode.DURATION
            else None
        )
        result = await _generate_tasks(
            goal_title=goal_title,
            hours_per_day=gen_data.hours_per_day,
            mode=gen_data.mode,
            duration=duration,
            max_days=max_days,
        )
        total_days = result["total_days"]
        real_target_date = (
            goal_target_date if gen_data.mode == GoalMode.DURATION
            else goal_start_date + timedelta(days=total_days)
        )
    except OpenAIRateLimitError:
        logger.warning("OpenAI rate limit hit for job %s", job_id_str)
        await _mark_failed(job_uuid, "OpenAI rate limit exceeded", ec.AI_SERVICE_ERROR.code)
        return
    except OpenAIAPIError as e:
        logger.exception("OpenAI API error for job %s: %s", job_id_str, e)
        await _mark_failed(job_uuid, f"OpenAI API error: {e}", ec.AI_SERVICE_ERROR.code)
        return
    except ValueError as e:
        logger.exception("AI response invalid for job %s: %s", job_id_str, e)
        await _mark_failed(job_uuid, str(e), ec.AI_RESPONSE_INVALID.code)
        return
    except Exception as e:
        logger.exception("Unexpected error in Phase 2 for job %s", job_id_str)
        await _mark_failed(job_uuid, str(e), ec.PLAN_GENERATION_FAILED.code)
        return

    # ── Phase 3: persist plan + tasks (goal already exists) ──────────────────
    try:
        async with AsyncSessionLocal() as db:
            job = await db.get(GoalJob, job_uuid)
            goal = await db.get(Goal, job.goal_id)

            # Update target_date when AI determined real duration (hours mode).
            if gen_data.mode == GoalMode.HOURS:
                goal.target_date = real_target_date

            plan = Plan(
                goal_id=goal.id,
                total_days=total_days,
                generated_by=PlanGeneratedBy.AI,
                overview=result.get("overview"),
                hours_per_day=gen_data.hours_per_day,
            )
            db.add(plan)
            await db.flush()

            for item in result["tasks"]:
                db.add(Task(
                    plan_id=plan.id,
                    day_number=item["day_number"],
                    execution_date=(
                        goal_start_date + timedelta(days=item["day_number"] - 1)
                    ),
                    title=item["title"],
                    description=item.get("description"),
                    explanation=item.get("explanation"),
                    guide=item.get("guide"),
                    estimated_minutes=item.get("estimated_minutes"),
                ))

            job.status = JobStatus.SUCCESS
            job.completed_at = datetime.utcnow()
            await db.commit()

        logger.info("Job %s completed — plan created for goal %s", job_id_str, goal.id)
        await ws_manager.notify(job_id_str, {
            "status": "success",
            "job_id": job_id_str,
            "goal_id": str(goal.id),
        })

    except Exception as e:
        logger.exception("DB write failed for job %s", job_id_str)
        await _mark_failed(job_uuid, str(e), ec.PLAN_GENERATION_FAILED.code)


async def _mark_failed(
    job_uuid: uuid.UUID,
    error: str,
    error_code: str = ec.INTERNAL_SERVER_ERROR.code,
) -> None:
    try:
        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(GoalJob).where(GoalJob.id == job_uuid)
            )
            job = result.scalar_one_or_none()
            if job:
                job.status = JobStatus.FAILED
                job.error_message = error[:1000]   # raw message stored for ops, never shown to users
                job.completed_at = datetime.utcnow()
                await db.commit()
                await ws_manager.notify(str(job_uuid), {
                    "status": "failed",
                    "job_id": str(job_uuid),
                    "error_code": error_code,  # safe code — Flutter maps this to a user-friendly message
                })
    except Exception:
        logger.exception("Could not mark job %s as failed", job_uuid)
