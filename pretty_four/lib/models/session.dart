class Session {
  final String id;
  final String childId;
  final DateTime recordedAt;
  final int durationSec;
  final String status;

  const Session({
    required this.id,
    required this.childId,
    required this.recordedAt,
    required this.durationSec,
    required this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        childId: json['childId'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        durationSec: json['durationSec'] as int,
        status: json['status'] as String,
      );

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'recordedAt': recordedAt.toIso8601String(),
        'durationSec': durationSec,
        'status': status,
      };
}
