import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviciul de locație e dezactivat');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisiunea a fost refuzată');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permisiunea e blocată permanent');
    }

    return Geolocator.getCurrentPosition();
  }
}
