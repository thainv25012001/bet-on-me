import uuid
import logging

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.core.ws_manager import ws_manager
from app.db.session import get_db
from app.models.goal_job import GoalJob
from app.repositories.user_repository import UserRepository
from app.utils.constants import JobStatus

logger = logging.getLogger(__name__)

router = APIRouter()


@router.websocket("/ws/jobs/{job_id}")
async def job_status_ws(
    job_id: uuid.UUID,
    websocket: WebSocket,
    token: str = Query(...),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Real-time job-completion notifications.

    The client connects immediately after receiving a job_id from POST /goals.
    The server pushes a single JSON message when the Kafka consumer finishes
    (success or failure), then the connection closes.

    Authentication: pass the JWT as the ``token`` query parameter — WebSocket
    clients cannot send custom headers during the handshake.
    """
    # ── 1. Authenticate ───────────────────────────────────────────────────────
    user_id_str, is_expired = decode_access_token(token)
    if is_expired or not user_id_str:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    try:
        user_uuid = uuid.UUID(user_id_str)
    except ValueError:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    repo = UserRepository(db)
    user = await repo.get(user_uuid)
    if not user:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    # ── 2. Validate job ownership ─────────────────────────────────────────────
    job: GoalJob | None = await db.get(GoalJob, job_id)
    if job is None or job.user_id != user_uuid:
        await websocket.close(code=4004, reason="Job not found")
        return

    # ── 3. Race-condition guard: job already finished ─────────────────────────
    if job.status in (JobStatus.SUCCESS, JobStatus.FAILED):
        await websocket.accept()
        await websocket.send_json({
            "status": job.status,
            "job_id": str(job.id),
            "goal_id": str(job.goal_id) if job.goal_id else None,
            "error_message": job.error_message,
        })
        await websocket.close()
        return

    # ── 4. Register and wait ──────────────────────────────────────────────────
    await ws_manager.connect(str(job_id), websocket)
    try:
        # Keep the connection alive.  The server closes it from
        # ws_manager.notify(); the client may also close it.
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect(str(job_id))
        logger.debug("Client disconnected from job WS %s", job_id)
