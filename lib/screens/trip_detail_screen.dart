import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/trip.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late GoogleMapController _mapController;
  late Set<Marker> _markers;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(widget.trip.startLat, widget.trip.startLng),
        infoWindow: InfoWindow(title: widget.trip.startLocation),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(widget.trip.endLat, widget.trip.endLng),
        infoWindow: InfoWindow(title: widget.trip.destination),
      ),
    };
    _getDirectionsRoute();
  }

  Future<void> _getDirectionsRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${widget.trip.startLat},${widget.trip.startLng}'
          '&destination=${widget.trip.endLat},${widget.trip.endLng}'
          '&mode=driving'
          '&key=AIzaSyCZt4iWsmr1Gjs5FflS-u6MQ9r_t_sG12I';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final points = _decodePolyline(
            data['routes'][0]['overview_polyline']['points']
          );

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                points: points,
                width: 5,
              ),
            );
          });
        } else {
          throw Exception('API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load route: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _getDirectionsRoute,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingRoute = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.trip.startLat, widget.trip.startLng),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              LatLngBounds bounds = LatLngBounds(
                southwest: LatLng(
                  math.min(widget.trip.startLat, widget.trip.endLat),
                  math.min(widget.trip.startLng, widget.trip.endLng),
                ),
                northeast: LatLng(
                  math.max(widget.trip.startLat, widget.trip.endLat),
                  math.max(widget.trip.startLng, widget.trip.endLng),
                ),
              );
              controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
            },
          ),

          // Loading indicator
          if (_isLoadingRoute)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading route...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top navigation bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Card(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Trip Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
          ),

          // Bottom details card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('From', widget.trip.startLocation),
                    const SizedBox(height: 8),
                    _buildDetailRow('To', widget.trip.destination),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Date',
                      DateFormat('MMM d, y HH:mm').format(widget.trip.date),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Fare', 
                      '₱${widget.trip.fare.toStringAsFixed(2)}',
                      valueColor: Colors.green,
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
} 