const String _releaseFolder =
    'https://download.documentfoundation.org/libreoffice/stable/26.8.2/mac/'
    'aarch64';
const String _imageName = 'LibreOffice_26.8.2_MacOS_aarch64.dmg';
const int _bytesInMegabyte = 1000000;

class ReleaseImage {
  const ReleaseImage({
    required this.address,
    required this.sha256,
    required this.bytes,
  });

  final String address;
  final String sha256;
  final int bytes;
}

const ReleaseImage libreOfficeRelease = ReleaseImage(
  address: '$_releaseFolder/$_imageName',
  sha256: '9f24fe83ab1ed5c95eb3df580119f32932f713e577feeac02bf619fb00749b55',
  bytes: 299236406,
);

String downloadSizeLabel(int bytes) {
  final megabytes = (bytes / _bytesInMegabyte).round();

  return '$megabytes MB';
}
