class StoreLocation {
  String? id;
  String address;
  String country;
  String city;
  String state;
  double latitude;
  double longitude;
  
  StoreLocation({
    this.id,
    required this.address,
    required this.country,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
  });
  
  Map<String, dynamic> toJson() {
    final data = {
      'address': address,
      'country': country,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (id != null) {
      data['id'] = id as String;
    }
    return data;
  }
  
  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      id: json['id']?.toString(),
      address: json['address'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }
}
