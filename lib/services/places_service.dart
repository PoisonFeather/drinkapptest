import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesService {
  static final String _apiKey = dotenv.env['API_KEY'] ?? "";

  static Future<List<Marker>> getNearbyBars(
    LatLng location,
    BuildContext? context,
    Function(String placeId, String placeName) onTapMarker,
  ) async {
    List<Map<String, dynamic>> allResults = [];
    String? nextPageToken;
    int pageCount = 0;

    do {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${location.latitude},${location.longitude}'
        '&radius=2500'
        '&keyword=bar|pub|club|beer|cocktail|alcool|vin|bere'
        '&key=$_apiKey'
        '${nextPageToken != null ? '&pagetoken=$nextPageToken' : ''}',
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        debugPrint('Eroare la API: ${data['status']}');
        break;
      }

      final results = List<Map<String, dynamic>>.from(data['results']);
      allResults.addAll(results);

      nextPageToken = data['next_page_token'];
      pageCount++;

      if (nextPageToken != null && pageCount < 3) {
        await Future.delayed(const Duration(seconds: 3));
      } else {
        break;
      }
    } while (nextPageToken != null);

    // Convertim în Markere
    return allResults.map((place) {
      final geometry = place['geometry']['location'];
      final name = place['name'];
      final placeId = place['place_id'];
      FirebaseService.placeNames[placeId] = name;

      return Marker(
        markerId: MarkerId(placeId),
        position: LatLng(geometry['lat'], geometry['lng']),

        // infoWindow: InfoWindow(
        //   title: name,
        onTap: () {
          onTapMarker(placeId, name);
        },
        // ),
        anchor: const Offset(0.5, 1.5),
      );
    }).toList();
  }
}
