class ErrorCode {
  final int id;
  final String code;
  final String type;
  final String message;
  final String cause;
  final String remedy;

  const ErrorCode({
    required this.id,
    required this.code,
    required this.type,
    required this.message,
    required this.cause,
    required this.remedy,
  });

  factory ErrorCode.fromMap(Map<String, dynamic> m) => ErrorCode(
        id: m['id'] as int,
        code: m['code'] as String? ?? '',
        type: m['type'] as String? ?? '',
        message: m['message'] as String? ?? '',
        cause: m['cause'] as String? ?? '',
        remedy: m['remedy'] as String? ?? '',
      );

  String get prefix => code.contains('-') ? code.split('-').first : code;
}
