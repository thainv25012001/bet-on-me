"""Central string constants for all status/type/mode values used across the app.

Import from here instead of using raw string literals so typos are caught at
import time and all valid values are discoverable in one place.
"""


class GoalStatus:
    IN_PROGRESS = "in_progress"
    SUCCESS = "success"
    FAILED = "failed"


class TaskStatus:
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"


class JobStatus:
    PENDING = "pending"
    PROCESSING = "processing"
    SUCCESS = "success"
    FAILED = "failed"


class SubscriptionStatus:
    ACTIVE = "active"
    CANCELLED = "cancelled"


class StakeStatus:
    ACTIVE = "active"


class PlanGeneratedBy:
    AI = "ai"


class GoalMode:
    DURATION = "duration"
    HOURS = "hours"
