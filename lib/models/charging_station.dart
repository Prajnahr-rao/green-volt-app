enum StationStatus {
  available,
  inUse,
  outOfService,
  underMaintenance,
}

enum ConnectorType {
  type2,
  ccs,
  chademo,
  tesla,
}

class ChargingStation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerKwh;
  final StationStatus status;
  final List<ConnectorType> connectorTypes;
  final double powerKw;
  final List<String> amenities;
  final String operatingHours;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<int> availableDurations;

  // Computed properties
  List<String> get availableChargerTypes {
    return connectorTypes.map((type) {
      switch (type) {
        case ConnectorType.type2:
          return 'Type 2';
        case ConnectorType.ccs:
          return 'CCS';
        case ConnectorType.chademo:
          return 'CHAdeMO';
        case ConnectorType.tesla:
          return 'Tesla';
        default:
          return 'Unknown';
      }
    }).toList();
  }

  ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerKwh,
    required this.status,
    required this.connectorTypes,
    required this.powerKw,
    this.amenities = const ['Parking'],
    this.operatingHours = '24/7',
    this.rating = 4.0,
    this.reviewCount = 0,
    this.imageUrl = '',
    this.availableDurations = const [30, 60, 90, 120],
  });

  // Factory method to create a station from a map
  factory ChargingStation.fromMap(Map<String, dynamic> map) {
    return ChargingStation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      pricePerKwh: map['pricePerKwh'] ?? 0.35,
      status: _parseStatus(map['status']),
      connectorTypes: _parseConnectorTypes(map['connectorTypes']),
      powerKw: map['powerKw'] ?? 50.0,
      amenities: List<String>.from(map['amenities'] ?? []),
      operatingHours: map['operatingHours'] ?? '24/7',
      rating: map['rating'] ?? 4.0,
      reviewCount: map['reviewCount'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      availableDurations: List<int>.from(map['availableDurations'] ?? [30, 60, 90, 120]),
    );
  }

  // Helper method to parse status
  static StationStatus _parseStatus(String? status) {
    if (status == null) return StationStatus.available;

    switch (status.toLowerCase()) {
      case 'in_use':
        return StationStatus.inUse;
      case 'out_of_service':
        return StationStatus.outOfService;
      case 'under_maintenance':
        return StationStatus.underMaintenance;
      case 'available':
      default:
        return StationStatus.available;
    }
  }

  // Helper method to parse connector types
  static List<ConnectorType> _parseConnectorTypes(List? types) {
    if (types == null || types.isEmpty) return [ConnectorType.type2];

    return types.map<ConnectorType>((type) {
      switch (type.toString().toLowerCase()) {
        case 'ccs':
          return ConnectorType.ccs;
        case 'chademo':
          return ConnectorType.chademo;
        case 'tesla':
          return ConnectorType.tesla;
        case 'type2':
        default:
          return ConnectorType.type2;
      }
    }).toList();
  }

  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerKwh': pricePerKwh,
      'status': status.toString().split('.').last,
      'connectorTypes': connectorTypes.map((type) => type.toString().split('.').last).toList(),
      'powerKw': powerKw,
      'amenities': amenities,
      'operatingHours': operatingHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'availableDurations': availableDurations,
    };
  }
}
