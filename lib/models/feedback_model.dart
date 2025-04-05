class FeedbackModel {
  final String vibe;
  final double crowdedness;
  final DateTime timestamp;

  FeedbackModel({
    required this.vibe,
    required this.crowdedness,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {'vibe': vibe, 'crowdedness': crowdedness, 'timestamp': timestamp};
  }
}
