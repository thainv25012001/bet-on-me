"""
Hourly background task that evaluates goal statuses.

Finds all in_progress goals whose target_date may have passed (UTC broad filter),
then checks each one in the user's local timezone via GoalService.evaluate_goal_status().

Follows the same asyncio.create_task pattern as the Kafka consumer.
"""
import asyncio
import logging
from datetime import date

from app.db.session import AsyncSessionLocal
from app.repositories.goal_repository import GoalRepository
from app.repositories.task_repository import TaskRepository
from app.services.goal_service import GoalService

logger = logging.getLogger(__name__)

_INTERVAL_SECONDS = 3600  # run once per hour


async def start_goal_evaluator() -> asyncio.Task:
    task = asyncio.create_task(_evaluation_loop())

    def _on_done(t: asyncio.Task) -> None:
        if not t.cancelled() and t.exception() is not None:
            logger.error("Goal evaluator crashed: %s", t.exception())

    task.add_done_callback(_on_done)
    logger.info("Goal evaluator started (interval=%ds)", _INTERVAL_SECONDS)
    return task


async def _evaluation_loop() -> None:
    try:
        while True:
            try:
                await _run_evaluation()
            except Exception:
                logger.exception("Goal evaluation run failed")
            await asyncio.sleep(_INTERVAL_SECONDS)
    except asyncio.CancelledError:
        pass
    finally:
        logger.info("Goal evaluator stopped")


async def _run_evaluation() -> None:
    # UTC date as broad cutoff — catches any goal whose target_date has passed
    # in at least some timezone. evaluate_goal_status() confirms per user timezone.
    cutoff = date.today()

    async with AsyncSessionLocal() as db:
        # Step 1: fail overdue pending tasks.
        failed_tasks = await TaskRepository(db).fail_overdue_tasks(cutoff)
        if failed_tasks:
            logger.info("Goal evaluator: marked %d overdue task(s) as failed", failed_tasks)

        # Step 2: evaluate goal statuses for goals whose deadline has passed.
        rows = await GoalRepository(db).get_in_progress_past_target(cutoff)
        goal_service = GoalService(db)
        evaluated = 0
        for goal, _tz in rows:
            try:
                await goal_service.evaluate_goal_status(goal)
                evaluated += 1
            except Exception:
                logger.exception("Failed to evaluate goal %s", goal.id)
        await db.commit()

    if evaluated:
        logger.info("Goal evaluator: checked %d goal(s)", evaluated)
