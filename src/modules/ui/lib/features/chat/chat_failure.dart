import '../../shared/api/api_error.dart';

const String genericChatFailure = 'Something went wrong. Try again.';
const int _chatUnavailableStatus = 503;

String chatFailureMessage(Exception failure) {
  if (failure is! ApiError) {
    return genericChatFailure;
  }

  if (failure.statusCode != _chatUnavailableStatus) {
    return genericChatFailure;
  }

  return failure.detail;
}
