class ApiError implements Exception {
  const ApiError({
    required this.statusCode,
    required this.path,
    required this.detail,
  });

  final int statusCode;
  final String path;
  final String detail;

  @override
  String toString() => detail;
}
