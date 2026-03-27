"""
Central registry of application error codes.

Each entry defines:
  - code         : machine-readable string sent in API responses
  - http_status  : HTTP status code
  - message      : internal/API-docs message (NOT shown raw to end users;
                   the Flutter client maps codes to its own safe copy)

Add new codes here whenever you raise a new AppException subclass or map
a new category of exception in the Kafka consumer.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class _ErrorCode:
    code: str
    http_status: int
    message: str


# ── Auth ──────────────────────────────────────────────────────────────────────
UNAUTHORIZED            = _ErrorCode("UNAUTHORIZED",            401, "Not authenticated.")
TOKEN_EXPIRED           = _ErrorCode("TOKEN_EXPIRED",           401, "Access token has expired.")
INVALID_CREDENTIALS     = _ErrorCode("INVALID_CREDENTIALS",     401, "Incorrect email or password.")
EMAIL_ALREADY_EXISTS    = _ErrorCode("EMAIL_ALREADY_EXISTS",    409, "Email is already registered.")

# ── Resource ──────────────────────────────────────────────────────────────────
NOT_FOUND               = _ErrorCode("NOT_FOUND",               404, "Resource not found.")
FORBIDDEN               = _ErrorCode("FORBIDDEN",               403, "Access denied.")

# ── Goal / Plan ───────────────────────────────────────────────────────────────
GOAL_NOT_FOUND          = _ErrorCode("GOAL_NOT_FOUND",          404, "Goal not found.")
JOB_NOT_FOUND           = _ErrorCode("JOB_NOT_FOUND",           404, "Goal creation job not found.")
AI_SERVICE_ERROR        = _ErrorCode("AI_SERVICE_ERROR",        503, "AI service unavailable.")
AI_RESPONSE_INVALID     = _ErrorCode("AI_RESPONSE_INVALID",     502, "AI returned an unexpected response.")
PLAN_GENERATION_FAILED  = _ErrorCode("PLAN_GENERATION_FAILED",  500, "Plan generation failed.")

# ── Subscription ──────────────────────────────────────────────────────────────
SUBSCRIPTION_REQUIRED   = _ErrorCode("SUBSCRIPTION_REQUIRED",   402, "Active subscription required.")
SUBSCRIPTION_EXPIRED    = _ErrorCode("SUBSCRIPTION_EXPIRED",    402, "Subscription has expired.")

# ── General ───────────────────────────────────────────────────────────────────
BAD_REQUEST             = _ErrorCode("BAD_REQUEST",             400, "Invalid request.")
CONFLICT                = _ErrorCode("CONFLICT",                409, "Conflict with existing data.")
RATE_LIMIT_EXCEEDED     = _ErrorCode("RATE_LIMIT_EXCEEDED",     429, "Too many requests.")
INTERNAL_SERVER_ERROR   = _ErrorCode("INTERNAL_SERVER_ERROR",   500, "An unexpected error occurred.")
