import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';
import '../screens/feedback_screen.dart';
import '../services/places_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  List<_MarkerLabel> _labels = [];
  double _currentZoom = 15;

  @override
  void initState() {
    super.initState();
    _loadLocationAndBars();
  }

  Future<void> _loadLocationAndBars() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Serviciul de locație este dezactivat.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permisiunea de locație a fost refuzată.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permisiunea de locație este permanent refuzată.');
    }

    final position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);

    final markers = await PlacesService.getNearbyBars(
      _currentPosition!,
      context,
      _openFeedbackSheet,
    );

    setState(() {
      _markers = Set.from(markers);
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (_mapController != null && _currentZoom >= 15) {
      final newLabels = await _createLabelsFromMarkers(markers);
      setState(() => _labels = newLabels);
    }
  }

  //Info Bar-uri negre de sub markere NU alea albe
  Future<List<_MarkerLabel>> _createLabelsFromMarkers(
    List<Marker> markers,
  ) async {
    final List<_MarkerLabel> labels = [];
    for (var marker in markers) {
      if (_mapController == null) continue;
      final screenCoordinate = await _mapController!.getScreenCoordinate(
        marker.position,
      );
      labels.add(
        _MarkerLabel(
          text: marker.infoWindow.title ?? '',
          screenPosition: screenCoordinate,
        ),
      );
    }
    return labels;
  }

  void _openFeedbackSheet(String placeId, String placeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(placeId: placeId, placeName: placeName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) {
                      setState(() {
                        _mapController = controller;
                      });
                    },
                    onCameraMove: (position) {
                      _currentZoom = position.zoom;
                    },
                    onCameraIdle: () async {
                      if (_mapController == null) return;
                      if (_currentZoom >= 15) {
                        final newLabels = await _createLabelsFromMarkers(
                          _markers.toList(),
                        );
                        setState(() => _labels = newLabels);
                      } else {
                        setState(() => _labels = []);
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 12,
                    ),
                    mapType: MapType.satellite,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers.toSet(),
                  ),
                  if (_currentZoom >= 15)
                    ..._labels.map(
                      (label) => Positioned(
                        left: label.screenPosition.x.toDouble() - 50,
                        top: label.screenPosition.y.toDouble(),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}

class _MarkerLabel {
  final String text;
  final ScreenCoordinate screenPosition;

  _MarkerLabel({required this.text, required this.screenPosition});
}
