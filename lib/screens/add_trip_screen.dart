import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/trip.dart';

class AddTripScreen extends StatefulWidget {
  final Function(Trip) onTripAdded;

  const AddTripScreen({super.key, required this.onTripAdded});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  LatLng? _startLocation;
  LatLng? _endLocation;
  bool _isLoading = false;
  double? _distanceInKm;
  static const double _ratePerKm = 50.0; // ₱50 per kilometer

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query, bool isStart) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        if (isStart) {
          _startLocation = latLng;
          _updateMarker('start', latLng, query);
        } else {
          _endLocation = latLng;
          _updateMarker('end', latLng, query);
        }

        if (_startLocation != null && _endLocation != null) {
          await _getRoute();
        }

        _updateMapView();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker(String id, LatLng position, String title) {
    _markers.removeWhere((m) => m.markerId.value == id);
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title),
      ),
    );
  }

  Future<void> _getRoute() async {
    if (_startLocation == null || _endLocation == null) return;

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_startLocation!.latitude},${_startLocation!.longitude}'
          '&destination=${_endLocation!.latitude},${_endLocation!.longitude}'
          '&mode=driving'
          '&key=AIzaSyCZt4iWsmr1Gjs5FflS-u6MQ9r_t_sG12I';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final points = _decodePolyline(
            data['routes'][0]['overview_polyline']['points']
          );

          // Get distance in kilometers
          _distanceInKm = data['routes'][0]['legs'][0]['distance']['value'] / 1000;

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                points: points,
                width: 5,
              ),
            );
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting route: $e')),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _updateMapView() {
    if (_mapController == null) return;

    if (_startLocation != null && _endLocation != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _startLocation!.latitude < _endLocation!.latitude
              ? _startLocation!.latitude
              : _endLocation!.latitude,
          _startLocation!.longitude < _endLocation!.longitude
              ? _startLocation!.longitude
              : _endLocation!.longitude,
        ),
        northeast: LatLng(
          _startLocation!.latitude > _endLocation!.latitude
              ? _startLocation!.latitude
              : _endLocation!.latitude,
          _startLocation!.longitude > _endLocation!.longitude
              ? _startLocation!.longitude
              : _endLocation!.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } else if (_startLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_startLocation!, 15),
      );
    } else if (_endLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_endLocation!, 15),
      );
    }
  }

  void _submitTrip() {
    if (_startLocation == null || 
        _endLocation == null || 
        _distanceInKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both locations')),
      );
      return;
    }

    final trip = Trip(
      startLocation: _startController.text,
      destination: _endController.text,
      startLat: _startLocation!.latitude,
      startLng: _startLocation!.longitude,
      endLat: _endLocation!.latitude,
      endLng: _endLocation!.longitude,
      date: DateTime.now(),
      fare: _distanceInKm! * _ratePerKm,
    );

    widget.onTripAdded(trip);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.5995, 120.9842), // Manila coordinates
              zoom: 11,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Search inputs
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _startController,
                      decoration: const InputDecoration(
                        labelText: 'Start Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onSubmitted: (value) => _searchLocation(value, true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _endController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onSubmitted: (value) => _searchLocation(value, false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Bottom card with fare and confirm button
          if (_distanceInKm != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Distance: ${_distanceInKm!.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estimated Fare: ₱${(_distanceInKm! * _ratePerKm).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitTrip,
                          child: const Text('Confirm Trip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 