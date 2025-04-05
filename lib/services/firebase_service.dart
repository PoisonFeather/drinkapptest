import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FirebaseService {
  static Map<String, String> placeNames = {}; // placeId -> name
  static Map<String, Map<String, dynamic>> feedbackStats = {};

  static Future<Map<String, dynamic>> getFeedbackStats(String placeId) async {
    print('[DEBUG] getFeedbackStats() for $placeId');

    final snapshot =
        await FirebaseFirestore.instance
            .collection('feedbacks')
            .doc(placeId)
            .collection('entries')
            .get();

    print('[DEBUG] Loaded ${snapshot.docs.length} feedbacks');

    if (snapshot.docs.isEmpty) {
      print('[DEBUG] No feedback found.');
      return {'avgCrowdedness': null, 'commonVibe': null, 'lastUpdated': null};
    }

    double totalCrowdedness = 0;
    Map<String, int> vibeCounts = {};
    DateTime? lastUpdated;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      print('[DEBUG] Data: $data');

      totalCrowdedness += (data['crowdedness'] ?? 0).toDouble();

      final vibe = data['vibe'] ?? 'Mid';
      vibeCounts[vibe] = (vibeCounts[vibe] ?? 0) + 1;

      final ts = (data['timestamp'] as Timestamp).toDate();
      if (lastUpdated == null || ts.isAfter(lastUpdated)) {
        lastUpdated = ts;
      }
    }

    final commonVibe =
        (vibeCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    final result = {
      'avgCrowdedness': totalCrowdedness / snapshot.docs.length,
      'commonVibe': commonVibe,
      'lastUpdated': lastUpdated,
    };

    print('[DEBUG] Stats result: $result');

    // 🔁 Salvează în cache pentru heatmap
    feedbackStats[placeId] = {
      'vibe': commonVibe,
      'avgCrowdedness': totalCrowdedness / snapshot.docs.length,
    };

    // ✅ Returnează și alte date pentru ecran
    return result;
  }

  static Future<void> sendFeedback(String placeId, FeedbackModel feedback) {
    return FirebaseFirestore.instance
        .collection('feedbacks')
        .doc(placeId)
        .collection('entries')
        .add(feedback.toJson());
  }
}
