import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.utils.exceptions import AppException
from app.schemas.common import error_response
from app.kafka.producer import start_producer, stop_producer
from app.kafka.consumer import start_consumer
from app.scheduler import start_goal_evaluator
from app.api.v1.routers import auth, users, goals, plans, tasks, stakes, payments, subscriptions, admin, ws, daily_rewards

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ──────────────────────────────────────────────────────────────
    await start_producer()
    consumer_task = await start_consumer()

    def _on_consumer_done(task: asyncio.Task) -> None:
        if not task.cancelled() and task.exception() is not None:
            logger.error("Kafka consumer crashed: %s", task.exception())

    consumer_task.add_done_callback(_on_consumer_done)

    evaluator_task = await start_goal_evaluator()

    yield

    # ── Shutdown ─────────────────────────────────────────────────────────────
    evaluator_task.cancel()
    try:
        await evaluator_task
    except asyncio.CancelledError:
        pass

    consumer_task.cancel()
    try:
        await consumer_task
    except asyncio.CancelledError:
        pass
    await stop_producer()


app = FastAPI(title="Bet on Me API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=error_response(exc.code, exc.message),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled exception: %s", exc)
    return JSONResponse(
        status_code=500,
        content=error_response("INTERNAL_SERVER_ERROR", "An unexpected error occurred"),
    )


@app.get("/health")
async def health():
    return {"status": "ok"}


PREFIX = "/api/v1"

app.include_router(auth.router, prefix=PREFIX)
app.include_router(users.router, prefix=PREFIX)
app.include_router(goals.router, prefix=PREFIX)
app.include_router(plans.router, prefix=PREFIX)
app.include_router(tasks.router, prefix=PREFIX)
app.include_router(stakes.router, prefix=PREFIX)
app.include_router(payments.router, prefix=PREFIX)
app.include_router(subscriptions.router, prefix=PREFIX)
app.include_router(admin.router, prefix=PREFIX)
app.include_router(daily_rewards.router, prefix=PREFIX)
app.include_router(ws.router)  # WebSocket routes — no /api/v1 prefix
