import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../main.dart';
import 'places_service.dart';

class BackgroundTask {
  static Future<void> checkAndNotify() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);

      final markers = await PlacesService.getNearbyBars(
        userLocation,
        null,
        (_, __) {}, // dummy callback
      );

      for (final marker in markers) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          marker.position.latitude,
          marker.position.longitude,
        );

        if (distance < 50) {
          await flutterLocalNotificationsPlugin.show(
            0,
            '🍻 Ești la ${marker.markerId.value}?',
            'Lasă-ne un feedback!',
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
          break;
        }
      }
    } catch (e) {
      print('[BACKGROUND ERROR]: $e');
    }
  }
}
