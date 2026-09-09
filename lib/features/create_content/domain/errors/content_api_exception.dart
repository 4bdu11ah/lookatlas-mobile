class ContentApiException implements Exception {
  const ContentApiException(
    this.message, {
    this.status,
    this.code,
    this.activeJobId,
    this.cancelled = false,
  });

  final String message;
  final int? status;
  final String? code;
  final String? activeJobId;
  final bool cancelled;

  @override
  String toString() => message;
}
