import logging
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """In-process WebSocket connection registry keyed by job_id.

    Works for a single-process uvicorn deployment (development / small
    production). For multi-worker deployments, replace with a Redis
    pub/sub-backed implementation.
    """

    def __init__(self) -> None:
        self._connections: dict[str, WebSocket] = {}

    async def connect(self, job_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._connections[job_id] = ws
        logger.debug("WS connected for job %s", job_id)

    def disconnect(self, job_id: str) -> None:
        self._connections.pop(job_id, None)
        logger.debug("WS disconnected for job %s", job_id)

    async def notify(self, job_id: str, data: dict) -> None:
        """Push *data* to the client watching *job_id*, then close the entry."""
        ws = self._connections.get(job_id)
        if ws is None:
            return
        try:
            await ws.send_json(data)
        except Exception:
            logger.debug("WS send failed for job %s (client already gone)", job_id)
        finally:
            self.disconnect(job_id)


ws_manager = ConnectionManager()
