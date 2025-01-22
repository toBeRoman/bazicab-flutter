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
} 