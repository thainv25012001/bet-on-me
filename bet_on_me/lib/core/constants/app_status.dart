/// Central string constants for all status/type/mode values used across the app.
///
/// Use these instead of raw string literals so typos are caught at compile
/// time and all valid values are discoverable in one place.

class TaskStatus {
  static const String pending = 'pending';
  static const String success = 'success';
  static const String failed = 'failed';
}

class GoalStatus {
  static const String draft = 'draft';
  static const String locked = 'locked';
  static const String inProgress = 'in_progress';
  static const String success = 'success';
  static const String failed = 'failed';
}

class JobStatus {
  static const String pending = 'pending';
  static const String success = 'success';
  static const String failed = 'failed';
}

class PlanMode {
  static const String duration = 'duration';
  static const String hours = 'hours';
}
