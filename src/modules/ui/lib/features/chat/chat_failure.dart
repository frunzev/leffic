import '../../shared/api/api_error.dart';

const String genericChatFailure = 'Something went wrong. Try again.';
const Set<int> _explainedStatuses = {402, 503};

String chatFailureMessage(Exception failure) {
  if (failure is! ApiError) {
    return genericChatFailure;
  }

  if (!_explainedStatuses.contains(failure.statusCode)) {
    return genericChatFailure;
  }

  return failure.detail;
}
