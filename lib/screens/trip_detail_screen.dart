import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map section
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.trip.startLat, widget.trip.startLng),
                zoom: 13,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                // Fit bounds to show both markers
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
                controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
              },
            ),
          ),
          // Details section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                _buildDetailRow('Fare', '₱${widget.trip.fare.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 