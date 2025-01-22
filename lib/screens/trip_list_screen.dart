import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import 'package:intl/intl.dart';
import '../widgets/trip_shimmer.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    await _tripService.addDummyData(); // Add some dummy data
    final trips = await _tripService.getTrips();
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        elevation: 0,
      ),
      body: _isLoading
          ? const TripShimmer()  // Use shimmer loading
          : _trips.isEmpty
              ? const Center(child: Text('No trips found'))
              : ListView.builder(
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          '${trip.startLocation} → ${trip.destination}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, y').format(trip.date),
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
                    );
                  },
                ),
    );
  }
} 