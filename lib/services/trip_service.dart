import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';

class TripService {
  static const String _cacheKey = 'cached_trips';
  static const String _lastUpdateKey = 'last_update';
  final Random _random = Random();
  final List<Trip> _trips = [];

  Future<List<Trip>> getTrips() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate random errors (1 in 3 chance)
    if (_random.nextInt(3) == 0) {
      throw Exception('Failed to load trips');
    }

    return _trips;
  }

  Future<void> addTrip(Trip trip) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _trips.add(trip);
    await _saveToCache();
  }

  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    
    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      _trips.clear();
      _trips.addAll(
        decoded.map((json) => Trip.fromJson(json)).toList(),
      );
      
      // If cache is older than 1 hour, refresh in background
      if (lastUpdate != null && 
          DateTime.now().millisecondsSinceEpoch - lastUpdate > 3600000) {
        _refreshInBackground();
      }
    }
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_trips.map((t) => t.toJson()).toList());
    await prefs.setString(_cacheKey, encoded);
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _refreshInBackground() async {
    try {
      await addDummyData();
      await _saveToCache();
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastUpdateKey);
    _trips.clear();
  }

  // Add some dummy data for testing
  Future<void> addDummyData() async {
    if (_trips.isEmpty) {
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
} 