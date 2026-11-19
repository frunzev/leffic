import '../design/toast.dart';

const String _missingLibreOfficeRefusal = 'LibreOffice is not installed at ';

const ToastMessage missingLibreOfficeMessage = ToastMessage(
  tone: ToastTone.failure,
  title: 'LibreOffice is not installed',
  detail: 'Download it in Settings to open Word, Excel and PowerPoint files.',
);

bool isMissingLibreOffice(String failureReason) {
  return failureReason.contains(_missingLibreOfficeRefusal);
}
