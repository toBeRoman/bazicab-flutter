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
      body: Stack(
        children: [
          // Full screen map
          GoogleMap(
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
              controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
            },
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