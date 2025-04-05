import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/feedback_model.dart';
import '../services/firebase_service.dart';
import 'package:share_plus/share_plus.dart';

class FeedbackScreen extends StatefulWidget {
  final String placeId;
  final String placeName;

  const FeedbackScreen({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _selectedVibe = 'Mid';
  double _crowdedness = 5;

  Map<String, dynamic>? _stats;
  List<String> _photoUrls = [];

  final List<Map<String, String>> vibeOptions = [
    {'label': 'Lame 😒', 'value': 'Lame'},
    {'label': 'Mid 😬', 'value': 'Mid'},
    {'label': 'Top 🤪', 'value': 'Top'},
  ];

  @override
  void initState() {
    super.initState();
    print('[DEBUG] initState called in FeedbackScreen');
    _loadStats();
    _loadPhotos();
  }

  Future<void> _loadStats() async {
    final stats = await FirebaseService.getFeedbackStats(widget.placeId);
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _loadPhotos() async {
    final apiKey = 'AIzaSyCxlfZ_j9P_M4Y1NAwXc1tY67Zpb-KHIU8';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=${widget.placeId}&fields=photos&key=$apiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final photos = data['result']['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        setState(() {
          _photoUrls =
              photos
                  .take(5)
                  .map(
                    (photo) =>
                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photo['photo_reference']}&key=$apiKey',
                  )
                  .toList();
        });
      }
    }
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'chiar acum';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min în urmă';
    if (diff.inHours < 24) return '${diff.inHours} h în urmă';
    return '${diff.inDays} zile în urmă';
  }

  void _submitFeedback() async {
    try {
      final feedback = FeedbackModel(
        vibe: _selectedVibe,
        crowdedness: _crowdedness,
        timestamp: DateTime.now(),
      );
      await FirebaseService.sendFeedback(widget.placeId, feedback);
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vibe-uri trimise cu succes!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.placeName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder:
                      (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_photoUrls[index]),
                      ),
                ),
              ),
            const SizedBox(height: 16),
            if (_stats != null && _stats!['avgCrowdedness'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("🔥 ", style: TextStyle(fontSize: 22)),
                  Text(
                    'Vibe: ${_stats!['commonVibe']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text("🚦 ", style: TextStyle(fontSize: 22)),
                  Text(
                    'Aglomerație medie: ${_stats!['avgCrowdedness'].toStringAsFixed(1)} / 10',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_stats!['lastUpdated'] != null)
                Row(
                  children: [
                    const Text("⏱️ ", style: TextStyle(fontSize: 18)),
                    Text(
                      'Ultima actualizare: ${timeAgo(_stats!['lastUpdated'])}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
            Text("Care-i vibe-ul?", style: const TextStyle(fontSize: 20)),
            DropdownButton<String>(
              value: _selectedVibe,
              onChanged: (value) => setState(() => _selectedVibe = value!),
              isExpanded: true,
              items:
                  vibeOptions.map((v) {
                    return DropdownMenuItem<String>(
                      value:
                          v['value'], // trebuie să corespundă cu _selectedVibe
                      child: Text(
                        v['label']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),
            Text('Cât de aglomerat e? (${_crowdedness.toInt()}/10)'),
            Slider(
              value: _crowdedness,
              min: 0,
              max: 10,
              divisions: 10,
              label: _crowdedness.round().toString(),
              onChanged: (value) => setState(() => _crowdedness = value),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Trimite Feedback'),
            ),
            Align(
              //share button
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final shareText = '''
🍻 Hai la ${widget.placeName} sa bem ceva!

📍 https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.placeName)}&query_place_id=${widget.placeId}

''';
                  Share.share(shareText);
                },
                icon: const Icon(Icons.arrow_circle_up_outlined, size: 18),
                label: const Text(
                  'Invita-ti prietenii',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
