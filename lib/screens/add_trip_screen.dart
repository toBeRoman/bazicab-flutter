import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  static const _apiKey = 'AIzaSyChOuKpfWNxzqlmDJH6R31DiTQTpCU2ZfE';

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _showLocationSearch(bool isStart) async {
    List<dynamic> predictions = [];
    bool isSearching = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isStart ? 'Search Start Location' : 'Search Destination',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter location',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) async {
                      if (value.length > 2) {
                        setState(() {
                          isSearching = true;
                        });

                        try {
                          final response = await http.get(
                            Uri.parse(
                              'https://maps.googleapis.com/maps/api/place/autocomplete/json'
                              '?input=${Uri.encodeComponent(value)}'
                              '&components=country:ph'
                              '&types=geocode'  // Add this to get more precise locations
                              '&key=$_apiKey'
                            ),
                          );

                          if (response.statusCode == 200) {
                            final data = json.decode(response.body);
                            if (data['status'] == 'OK') {
                              setState(() {
                                predictions = data['predictions'];
                                isSearching = false;
                              });
                            } else {
                              throw Exception(data['error_message'] ?? 'Failed to get predictions');
                            }
                          } else {
                            throw Exception('Failed to fetch predictions');
                          }
                        } catch (e) {
                          setState(() {
                            isSearching = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } else {
                        setState(() {
                          predictions = [];
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: predictions.isEmpty
                        ? Center(
                            child: Text(
                              isSearching 
                                  ? 'Searching...'
                                  : predictions.isEmpty 
                                      ? 'Enter at least 3 characters to search'
                                      : 'No results found',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: predictions.length,
                            itemBuilder: (context, index) {
                              final prediction = predictions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(
                                  prediction['structured_formatting']['main_text'] ?? '',
                                ),
                                subtitle: Text(
                                  prediction['structured_formatting']['secondary_text'] ?? '',
                                ),
                                onTap: () async {
                                  setState(() => isSearching = true);
                                  try {
                                    // Get place details
                                    final details = await http.get(
                                      Uri.parse(
                                        'https://maps.googleapis.com/maps/api/place/details/json'
                                        '?place_id=${prediction['place_id']}'
                                        '&fields=geometry,formatted_address'
                                        '&key=$_apiKey'
                                      ),
                                    );

                                    if (details.statusCode == 200) {
                                      final data = json.decode(details.body);
                                      if (data['status'] == 'OK') {
                                        final location = data['result']['geometry']['location'];
                                        final latLng = LatLng(location['lat'], location['lng']);
                                        final address = data['result']['formatted_address'];

                                        if (isStart) {
                                          _startController.text = address;
                                          _startLocation = latLng;
                                          _updateMarker('start', latLng, address);
                                        } else {
                                          _endController.text = address;
                                          _endLocation = latLng;
                                          _updateMarker('end', latLng, address);
                                        }

                                        if (_startLocation != null && _endLocation != null) {
                                          await _getRoute();
                                        }

                                        _updateMapView();
                                        Navigator.pop(context);
                                      }
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  } finally {
                                    setState(() => isSearching = false);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

    setState(() {
      _isLoading = true;
    });

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_startLocation!.latitude},${_startLocation!.longitude}'
          '&destination=${_endLocation!.latitude},${_endLocation!.longitude}'
          '&mode=driving'
          '&key=$_apiKey';

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
        } else {
          throw Exception(data['error_message'] ?? 'Failed to get route');
        }
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                    // Start location field
                    TextField(
                      controller: _startController,
                      decoration: InputDecoration(
                        labelText: 'Start Location',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _startController.clear();
                            setState(() {
                              _startLocation = null;
                              _markers.removeWhere(
                                (m) => m.markerId.value == 'start'
                              );
                              _polylines.clear();
                              _distanceInKm = null;
                            });
                          },
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _showLocationSearch(true),
                    ),
                    const SizedBox(height: 8),
                    // Destination field
                    TextField(
                      controller: _endController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _endController.clear();
                            setState(() {
                              _endLocation = null;
                              _markers.removeWhere(
                                (m) => m.markerId.value == 'end'
                              );
                              _polylines.clear();
                              _distanceInKm = null;
                            });
                          },
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _showLocationSearch(false),
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