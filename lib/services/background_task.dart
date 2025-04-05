import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../main.dart';
import 'places_service.dart';
import 'firebase_service.dart';

class BackgroundTask {
  // Baruri pentru care s-a trimis deja notificare
  static final Set<String> notifiedBars = {};

  static Future<void> checkAndNotify() async {
    print('[BackgroundTask] Rulez verificarea de proximitate...');

    // await flutterLocalNotificationsPlugin.show(
    //   999,
    //   '🔔 Test notificare din background',
    //   'Taskul rulează corect!',
    //   const NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'test_channel',
    //       'Test Channel',
    //       importance: Importance.high,
    //       priority: Priority.high,
    //     ),
    //     iOS: DarwinNotificationDetails(),
    //   ),
    // );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);

      final markers = await PlacesService.getNearbyBars(
        userLocation,
        null, // context not needed
        (_, __) {}, // dummy callback
      );

      for (final marker in markers) {
        final placeId = marker.markerId.value;

        // Verifică dacă am notificat deja barul
        //if (notifiedBars.contains(placeId)) continue;

        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          marker.position.latitude,
          marker.position.longitude,
        );

        if (distance < 100) {
          //notifiedBars.add(placeId); // ✅ adaugă barul în lista celor notificate

          final barName = FirebaseService.placeNames[placeId] ?? 'acest bar';
          print('Notificare pentru ${FirebaseService.placeNames[placeId]}');
          await flutterLocalNotificationsPlugin.show(
            0,
            '🍻 Ești la $barName?',
            'Spune-ne care-i vibe-ul!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'bar_channel',
                'Bar Reminder',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );

          break; // o singură notificare per rundă
        }
      }
    } catch (e) {
      print('[BackgroundTask] Eroare: $e');
    }
  }
}
