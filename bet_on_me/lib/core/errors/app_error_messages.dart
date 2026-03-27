import 'package:bet_on_me/core/services/api_client.dart';

/// Maps backend error codes to safe, user-friendly display messages.
///
/// The backend sends a machine-readable [code] in every error response.
/// This class is the single place where codes are translated into text
/// the user actually sees — keeping technical details out of the UI.
///
/// To add a new message: add the code constant and an entry in [_messages].
class AppErrorMessages {
  AppErrorMessages._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const unauthorized         = 'UNAUTHORIZED';
  static const tokenExpired         = 'TOKEN_EXPIRED';
  static const invalidCredentials   = 'INVALID_CREDENTIALS';
  static const emailAlreadyExists   = 'EMAIL_ALREADY_EXISTS';

  // ── Resource ──────────────────────────────────────────────────────────────
  static const notFound             = 'NOT_FOUND';
  static const forbidden            = 'FORBIDDEN';
  static const goalNotFound         = 'GOAL_NOT_FOUND';
  static const jobNotFound          = 'JOB_NOT_FOUND';
  static const goalLimitReached     = 'GOAL_LIMIT_REACHED';

  // ── Goal / Plan ───────────────────────────────────────────────────────────
  static const aiServiceError       = 'AI_SERVICE_ERROR';
  static const aiResponseInvalid    = 'AI_RESPONSE_INVALID';
  static const planGenerationFailed = 'PLAN_GENERATION_FAILED';

  // ── Subscription ──────────────────────────────────────────────────────────
  static const subscriptionRequired = 'SUBSCRIPTION_REQUIRED';
  static const subscriptionExpired  = 'SUBSCRIPTION_EXPIRED';

  // ── General ───────────────────────────────────────────────────────────────
  static const badRequest           = 'BAD_REQUEST';
  static const conflict             = 'CONFLICT';
  static const rateLimitExceeded    = 'RATE_LIMIT_EXCEEDED';
  static const internalServerError  = 'INTERNAL_SERVER_ERROR';

  static const _fallback = 'Something went wrong. Please try again.';

  static const Map<String, String> _messages = {
    // Auth
    unauthorized:
        'Please sign in to continue.',
    tokenExpired:
        'Your session has expired. Please sign in again.',
    invalidCredentials:
        'Incorrect email or password.',
    emailAlreadyExists:
        'An account with this email already exists.',

    // Resource
    notFound:
        'The requested item could not be found.',
    forbidden:
        "You don't have permission to do this.",
    goalNotFound:
        'This goal no longer exists.',
    jobNotFound:
        'Could not find the creation job. Please try again.',
    goalLimitReached:
        "You've reached the goal limit for your current plan. Upgrade to add more goals.",

    // Goal / Plan — no technical details exposed
    aiServiceError:
        'Our planning service is temporarily unavailable. Please try again later.',
    aiResponseInvalid:
        "We couldn't generate a plan for this goal. Please try again.",
    planGenerationFailed:
        'Plan generation failed. Please try again.',

    // Subscription
    subscriptionRequired:
        'This feature requires an active subscription.',
    subscriptionExpired:
        'Your subscription has expired. Please renew to continue.',

    // General
    badRequest:
        'Invalid request. Please check your input and try again.',
    conflict:
        'A conflict occurred. Please refresh and try again.',
    rateLimitExceeded:
        'Too many requests. Please wait a moment and try again.',
    internalServerError:
        'Something went wrong on our end. Please try again.',
  };

  /// Returns the display message for the given error [code].
  /// Falls back to a generic message for unknown or null codes.
  static String fromCode(String? code) =>
      code != null ? _messages[code] ?? _fallback : _fallback;

  /// Returns the display message for an [ApiException].
  static String fromException(Object error) {
    if (error is ApiException) return fromCode(error.code);
    return _fallback;
  }
}
