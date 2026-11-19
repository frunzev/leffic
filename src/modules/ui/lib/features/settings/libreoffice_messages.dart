import '../../shared/design/toast.dart';

const ToastMessage libreOfficeDownloadingMessage = ToastMessage(
  tone: ToastTone.progress,
  title: 'Downloading LibreOffice',
  detail: 'You can keep working while it downloads.',
);

const ToastMessage libreOfficeInstalledMessage = ToastMessage(
  tone: ToastTone.success,
  title: 'LibreOffice installed',
  detail: 'Word, Excel and PowerPoint files open in Leffic now.',
);

ToastMessage libreOfficeFailureMessage(String reason) {
  return ToastMessage(
    tone: ToastTone.failure,
    title: "Couldn't install LibreOffice",
    detail: reason,
  );
}
