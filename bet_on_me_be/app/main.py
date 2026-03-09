import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.utils.exceptions import AppException
from app.schemas.common import error_response
from app.api.v1.routers import auth, users, goals, plans, tasks, checkins, stakes, payments

logger = logging.getLogger(__name__)

app = FastAPI(title="Bet on Me API", version="1.0.0")

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
app.include_router(checkins.router, prefix=PREFIX)
app.include_router(stakes.router, prefix=PREFIX)
app.include_router(payments.router, prefix=PREFIX)
