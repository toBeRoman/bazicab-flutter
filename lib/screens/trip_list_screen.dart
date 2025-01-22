import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import 'package:intl/intl.dart';
import '../widgets/trip_shimmer.dart';
import 'trip_detail_screen.dart';
import 'add_trip_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = true;
  final Map<int, String> _startAddresses = {};
  final Map<int, String> _endAddresses = {};

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}';
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return 'Unknown location';
  }

  Future<void> _loadAddresses(Trip trip, int index) async {
    _startAddresses[index] = await _getAddressFromLatLng(
      trip.startLat,
      trip.startLng,
    );
    _endAddresses[index] = await _getAddressFromLatLng(
      trip.endLat,
      trip.endLng,
    );
    setState(() {});
  }

  Future<void> _loadTrips() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      await _tripService.loadFromCache(); // Load cached data first
      final trips = await _tripService.getTrips();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
      
      // Load addresses for each trip
      for (var i = 0; i < trips.length; i++) {
        _loadAddresses(trips[i], i);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadTrips,
            ),
          ),
        );
      }
    }
  }

  void _addNewTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTripScreen(
          onTripAdded: (trip) async {
            await _tripService.addTrip(trip);
            if (mounted) {
              _loadTrips();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip, int index) {
    final startAddress = _startAddresses[index] ?? 'Loading...';
    final endAddress = _endAddresses[index] ?? 'Loading...';
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          // Mini Map
          SizedBox(
            height: 120,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(trip.startLat, trip.startLng),
                  zoom: 12,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('start_$index'),
                    position: LatLng(trip.startLat, trip.startLng),
                  ),
                  Marker(
                    markerId: MarkerId('end_$index'),
                    position: LatLng(trip.endLat, trip.endLng),
                  ),
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: true, // Use lite mode for better performance
              ),
            ),
          ),
          // Trip Details
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_downward, size: 16),
                Text(
                  endAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(DateFormat('MMM d, y').format(trip.date)),
            ),
            trailing: Text(
              '₱${trip.fare.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailScreen(trip: trip),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewTrip,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading
            ? const TripShimmer()
            : _trips.isEmpty
                ? ListView(
                    children: const [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No trips found'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) => _buildTripCard(_trips[index], index),
                  ),
      ),
    );
  }
} 