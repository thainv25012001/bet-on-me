from fastapi import HTTPException
from app.utils import error_codes as ec


class AppException(HTTPException):
    def __init__(self, status_code: int, code: str, message: str) -> None:
        self.code = code
        self.message = message
        super().__init__(
            status_code=status_code,
            detail={"code": code, "message": message},
        )


class NotFound(AppException):
    def __init__(self, resource: str = "Resource") -> None:
        code = (
            ec.GOAL_NOT_FOUND if resource == "Goal"
            else ec.JOB_NOT_FOUND if resource == "GoalJob"
            else ec.NOT_FOUND
        )
        super().__init__(
            status_code=code.http_status,
            code=code.code,
            message=code.message,
        )


class Forbidden(AppException):
    def __init__(self) -> None:
        super().__init__(
            status_code=ec.FORBIDDEN.http_status,
            code=ec.FORBIDDEN.code,
            message=ec.FORBIDDEN.message,
        )


class Unauthorized(AppException):
    def __init__(self) -> None:
        super().__init__(
            status_code=ec.UNAUTHORIZED.http_status,
            code=ec.UNAUTHORIZED.code,
            message=ec.UNAUTHORIZED.message,
        )


class TokenExpired(AppException):
    def __init__(self) -> None:
        super().__init__(
            status_code=ec.TOKEN_EXPIRED.http_status,
            code=ec.TOKEN_EXPIRED.code,
            message=ec.TOKEN_EXPIRED.message,
        )


class BadRequest(AppException):
    def __init__(self, message: str | None = None) -> None:
        super().__init__(
            status_code=ec.BAD_REQUEST.http_status,
            code=ec.BAD_REQUEST.code,
            message=message or ec.BAD_REQUEST.message,
        )


class Conflict(AppException):
    def __init__(self, message: str | None = None) -> None:
        super().__init__(
            status_code=ec.CONFLICT.http_status,
            code=ec.CONFLICT.code,
            message=message or ec.CONFLICT.message,
        )


class SubscriptionRequired(AppException):
    def __init__(self) -> None:
        super().__init__(
            status_code=ec.SUBSCRIPTION_REQUIRED.http_status,
            code=ec.SUBSCRIPTION_REQUIRED.code,
            message=ec.SUBSCRIPTION_REQUIRED.message,
        )


class GoalLimitReached(AppException):
    def __init__(self, limit: int) -> None:
        super().__init__(
            status_code=ec.GOAL_LIMIT_REACHED.http_status,
            code=ec.GOAL_LIMIT_REACHED.code,
            message=f"You have reached the {limit}-goal limit for your current plan.",
        )


class AiServiceError(AppException):
    def __init__(self) -> None:
        super().__init__(
            status_code=ec.AI_SERVICE_ERROR.http_status,
            code=ec.AI_SERVICE_ERROR.code,
            message=ec.AI_SERVICE_ERROR.message,
        )


class PlanGenerationFailed(AppException):
    def __init__(self) -> None:
        super().__init__(
            status_code=ec.PLAN_GENERATION_FAILED.http_status,
            code=ec.PLAN_GENERATION_FAILED.code,
            message=ec.PLAN_GENERATION_FAILED.message,
        )
