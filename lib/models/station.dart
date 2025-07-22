class Station {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final List<String> availableChargerTypes;
  final int totalChargers;
  final int availableChargers;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final String operatingHours;
  final bool available;
  final String type;
  final String distance;
  final String price;
  final dynamic vehicle;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.availableChargerTypes,
    required this.totalChargers,
    required this.availableChargers,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.operatingHours,
    required this.available,
    required this.type,
    required this.distance,
    required this.price,
    required this.vehicle,
  });

  // Factory constructor to create a Station from a map (from database)
  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imageUrl: map['imageUrl'],
      availableChargerTypes: List<String>.from(map['availableChargerTypes']),
      totalChargers: map['totalChargers'],
      availableChargers: map['availableChargers'],
      rating: map['rating'],
      reviewCount: map['reviewCount'],
      amenities: List<String>.from(map['amenities']),
      operatingHours: map['operatingHours'],
      available: map['available'],
      type: map['type'],
      distance: map['distance'],
      price: map['price'],
      vehicle: map['vehicle'],
    );
  }
  // Convert station to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'availableChargerTypes': availableChargerTypes,
      'totalChargers': totalChargers,
      'availableChargers': availableChargers,
      'rating': rating,
      'reviewCount': reviewCount,
      'amenities': amenities,
      'operatingHours': operatingHours,
      'available': available,
      'type': type,
      'distance': distance,
      'price': price,
      'vehicle': vehicle,
    };
  }
}
