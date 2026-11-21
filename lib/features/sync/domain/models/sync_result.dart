/// লোকাল সিঙ্কের ফলাফল মডেল।
class SyncResult {
  final bool isSuccess;
  final String message;
  final DateTime timestamp;
  final int? bytesTransferred;

  const SyncResult({
    required this.isSuccess,
    required this.message,
    required this.timestamp,
    this.bytesTransferred,
  });

  factory SyncResult.success({
    String message = 'ফোন থেকে ডেটা সফলভাবে পিসিতে আপডেট হয়েছে!',
    int? bytesTransferred,
  }) =>
      SyncResult(
        isSuccess: true,
        message: message,
        timestamp: DateTime.now(),
        bytesTransferred: bytesTransferred,
      );

  factory SyncResult.failure(String errorMessage) => SyncResult(
        isSuccess: false,
        message: errorMessage,
        timestamp: DateTime.now(),
      );
}
