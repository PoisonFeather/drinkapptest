import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';
import '../screens/feedback_screen.dart';
import '../services/places_service.dart';
import '../services/background_task.dart';
import '../services/heatmap_painter.dart';
import '../models/heat_point.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

double zoom = 17;

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
  bool _showHeatmap = false;
  List<HeatPoint> _heatPoints = [];
  Timer? _updateTimer;

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
    await _loadAllFeedbackStats();
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
      final placeId = marker.markerId.value;
      final name = FirebaseService.placeNames[placeId];

      if (name == null) continue; // Sari peste markerii fără nume

      labels.add(
        _MarkerLabel(id: placeId, text: name, screenPosition: screenCoordinate),
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

  ///---------------------------------------------------------------------------
  /// HEATMAP - _updateHeatmapPoints() :
  /// ia marker position , vibe si crowd(intesnitate)
  /// adauga un obiect HeatPoint la points
  ///
  /// --------------------------------------------------------------------------
  Future<void> _updateHeatmapPoints(double currzoom) async {
    //print("Heatmap loading...");
    if (_mapController == null) return;

    final List<HeatPoint> points = [];

    for (var marker in _markers) {
      final stat = FirebaseService.feedbackStats[marker.markerId.value];
      if (stat == null) continue;

      final screenCoord = await _mapController!.getScreenCoordinate(
        marker.position,
      );
      final offset = Offset(screenCoord.x.toDouble(), screenCoord.y.toDouble());

      final vibe = stat['vibe'] ?? 'Mid';
      final crowded = (stat['avgCrowdedness'] ?? 5).toDouble();

      final color =
          vibe == 'Top'
              ? Colors.red
              : vibe == 'Mid'
              ? Colors.orange
              : Colors.blue;
      //print(color);
      points.add(HeatPoint(offset, color, crowded, currzoom));
    }

    setState(() {
      _heatPoints = points;
    });
  }

  ///---------------------------------------------------------------------------
  /// Map View : _scheduleFullUpdate():
  ///  da un sleep async care sa dea update la heatpoints
  ///  -------------------------------------------------------------------------
  void _scheduleFullUpdate(double currzoom) {
    if (_updateTimer?.isActive ?? false) return;

    _updateTimer = Timer(const Duration(milliseconds: 20), () async {
      if (_currentZoom >= zoom) {
        final newLabels = await _createLabelsFromMarkers(_markers.toList());
        setState(() => _labels = newLabels);

        if (_showHeatmap) {
          await _updateHeatmapPoints(currzoom);
        }
      } else {
        setState(() {
          _labels = [];
          _heatPoints = [];
        });
      }
    });
  }

  ///---------------------------------------------------------------------------
  ///  _loadAllFeedbackStats() :  incarca toate statisticile pentru
  ///  toate markerele
  ///  -------------------------------------------------------------------------
  Future<void> _loadAllFeedbackStats() async {
    for (var marker in _markers) {
      // Apelează getFeedbackStats pentru fiecare marker (placeId)
      final stats = await FirebaseService.getFeedbackStats(
        marker.markerId.value,
      );
      // Salvează rezultatul în feedbackStats (care e un Map)
      FirebaseService.feedbackStats[marker.markerId.value] = stats;
    }
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
                      _scheduleFullUpdate(_currentZoom); // ⚡ update continuu
                    },
                    onCameraIdle: () async {
                      if (_mapController == null) return;
                      if (_currentZoom >= zoom) {
                        final newLabels = await _createLabelsFromMarkers(
                          _markers.toList(),
                        );
                        setState(() => _labels = newLabels);
                        if (_showHeatmap) {
                          await _updateHeatmapPoints(
                            _currentZoom,
                          ); // 🔥 REGENEREAZĂ punctele în poziție corectă
                        }
                      } else {
                        setState(() => _labels = []);
                        _labels = [];
                        _heatPoints = [];
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: zoom,
                    ),
                    mapType: MapType.satellite,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers.toSet(),
                  ),
                  if (_showHeatmap)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: HeatmapPainter(_heatPoints),
                        ),
                      ),
                    ),

                  if (_currentZoom >= zoom)
                    ..._labels.map(
                      (label) => Positioned(
                        left: label.screenPosition.x.toDouble() - 50,
                        top: label.screenPosition.y.toDouble(),
                        child: GestureDetector(
                          onTap: () {
                            final placeId =
                                label
                                    .id; // trebuie să adăugăm și `id` în _MarkerLabel
                            final name =
                                FirebaseService.placeNames[placeId] ?? 'Bar';
                            _openFeedbackSheet(placeId, name);
                          },
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
                    ),
                  Positioned(
                    top: 40,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'heatmap_toggle',
                      backgroundColor: Colors.deepPurple,
                      onPressed: () async {
                        if (!_showHeatmap) {
                          await _updateHeatmapPoints(
                            1,
                          ); // generează punctele înainte să le afișezi
                        }
                        setState(() {
                          _showHeatmap = !_showHeatmap;
                        });
                      },

                      child: Icon(
                        _showHeatmap ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _MarkerLabel {
  final String id; // placeId
  final String text;
  final ScreenCoordinate screenPosition;

  _MarkerLabel({
    required this.id,
    required this.text,
    required this.screenPosition,
  });
}
