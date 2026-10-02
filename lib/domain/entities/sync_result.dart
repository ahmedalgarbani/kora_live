/// Outcome of fetching stream links from the server.
class SyncResult {
  final int added;
  final int updated;
  final int removed;

  /// Optional announcement text sent by the server.
  final String? message;
  final DateTime syncedAt;

  const SyncResult({
    required this.added,
    required this.updated,
    required this.removed,
    required this.syncedAt,
    this.message,
  });

  int get total => added + updated;
}
