class CalendarApiException implements Exception {
  const CalendarApiException(this.message, {this.code, this.status});

  final String message;
  final String? code;
  final int? status;

  @override
  String toString() => message;
}
