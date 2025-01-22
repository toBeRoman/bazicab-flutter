import '../models/trip.dart';

class TripService {
  final List<Trip> _trips = [];

  Future<List<Trip>> getTrips() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return _trips;
  }

  Future<void> addTrip(Trip trip) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _trips.add(trip);
  }

  // Add some dummy data for testing
  Future<void> addDummyData() async {
    await addTrip(
      Trip(
        startLocation: "Home",
        destination: "Office",
        startLat: 14.5995,
        startLng: 120.9842,
        endLat: 14.5547,
        endLng: 121.0244,
        date: DateTime.now().subtract(const Duration(days: 1)),
        fare: 250.0,
      ),
    );
    await addTrip(
      Trip(
        startLocation: "Mall",
        destination: "Restaurant",
        startLat: 14.5547,
        startLng: 121.0244,
        endLat: 14.5995,
        endLng: 120.9842,
        date: DateTime.now().subtract(const Duration(days: 2)),
        fare: 180.0,
      ),
    );
  }
} 