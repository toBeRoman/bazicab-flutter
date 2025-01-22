class Trip {
  final String startLocation;
  final String destination;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final DateTime date;
  final double fare;

  Trip({
    required this.startLocation,
    required this.destination,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.date,
    required this.fare,
  });

  Map<String, dynamic> toJson() => {
        'startLocation': startLocation,
        'destination': destination,
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'date': date.toIso8601String(),
        'fare': fare,
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        startLocation: json['startLocation'],
        destination: json['destination'],
        startLat: json['startLat'],
        startLng: json['startLng'],
        endLat: json['endLat'],
        endLng: json['endLng'],
        date: DateTime.parse(json['date']),
        fare: json['fare'],
      );
} 