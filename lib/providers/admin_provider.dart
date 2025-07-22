import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/charging_station.dart';
import '../models/service.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/location.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  // Sample data for charging stations
  List<ChargingStation> _stations = [
    ChargingStation(
      id: '1',
      name: 'Downtown Charging Hub',
      address: '123 Main St, Anytown, USA',
      latitude: 37.7749,
      longitude: -122.4194,
      pricePerKwh: 0.35,
      status: StationStatus.available,
      connectorTypes: [ConnectorType.type2, ConnectorType.ccs],
      powerKw: 150.0,
    ),
    ChargingStation(
      id: '2',
      name: 'Westside EV Station',
      address: '456 Oak Ave, Anytown, USA',
      latitude: 37.7833,
      longitude: -122.4167,
      pricePerKwh: 0.40,
      status: StationStatus.inUse,
      connectorTypes: [ConnectorType.type2, ConnectorType.chademo],
      powerKw: 50.0,
    ),
    ChargingStation(
      id: '3',
      name: 'Eastside Supercharger',
      address: '789 Pine Rd, Anytown, USA',
      latitude: 37.7850,
      longitude: -122.4100,
      pricePerKwh: 0.45,
      status: StationStatus.available,
      connectorTypes: [ConnectorType.tesla],
      powerKw: 250.0,
    ),
  ];

  // Add this new field for services
  List<Service> _services = [
    Service(
      id: '1',
      name: 'Basic Charging',
      description: 'Standard EV charging service',
      price: 25.99,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Service(
      id: '2',
      name: 'Premium Charging',
      description: 'Fast charging with priority access',
      price: 39.99,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Service(
      id: '3',
      name: 'Maintenance Check',
      description: 'Basic vehicle maintenance inspection',
      price: 49.99,
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];

  // Add this new field for store
  Store? _store = Store(
    id: '1',
    name: 'EV Charging Store',
    description: 'Your one-stop shop for all EV charging needs and accessories.',
    imageUrl: 'https://via.placeholder.com/150',
  );

  // Add this new field for products
  List<Product> _products = [
    Product(
      id: '1',
      name: 'EV Charging Cable',
      description: 'High-quality charging cable compatible with all Type 2 connectors.',
      price: 49.99,
      stockQuantity: 25,
      imageUrl: 'https://via.placeholder.com/150',
      category: 'Cables & Adapters',
    ),
    Product(
      id: '2',
      name: 'Portable EV Charger',
      description: 'Compact and lightweight portable charger for emergency use.',
      price: 199.99,
      stockQuantity: 15,
      imageUrl: 'https://via.placeholder.com/150',
      category: 'Chargers',
    ),
    Product(
      id: '3',
      name: 'Wall Mount Bracket',
      description: 'Sturdy wall mount bracket for home charging stations.',
      price: 29.99,
      stockQuantity: 40,
      imageUrl: 'https://via.placeholder.com/150',
      category: 'Accessories',
    ),
  ];

  // Add this new field for location
  StoreLocation? _location = StoreLocation(
    id: '1',
    address: '123 EV Charging Way, Electric City, EC 12345',
    country: 'United States',
    city: 'Electric City',
    state: 'EC',
    latitude: 37.7749,
    longitude: -122.4194,
  );

  // Getters
  List<User> get users => _users;
  List<ChargingStation> get stations => _stations;
  List<Service> get services => _services;
  Store? get store => _store;
  List<Product> get getProducts => _products;
  
  // Add this new getter
  StoreLocation? get location => _location;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize users from API
  Future<void> initializeUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final usersData = await _apiService.getUsers();
      _users = usersData.map((userData) => User(
        id: userData['id'].toString(),
        name: userData['name'],
        email: userData['email'],
        role: _parseUserRole(userData['role']),
        dateJoined: DateTime.parse(userData['created_at']),
      )).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'employee':
        return UserRole.employee;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.user;
    }
  }

  // User management methods
  Future<void> addUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.registerUser(
        name: user.name,
        email: user.email,
        password: user.password ?? '', // Ensure password is provided
        role: user.role.toString().split('.').last, // Convert enum to string
      );

      // After successful registration, refresh the users list
      await initializeUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement update user API call
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement delete user API call
      _users.removeWhere((user) => user.id == userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Station management methods
  void addStation(ChargingStation station) {
    _stations.add(station);
    notifyListeners();
  }

  void updateStation(ChargingStation station) {
    final index = _stations.indexWhere((s) => s.id == station.id);
    if (index != -1) {
      _stations[index] = station;
      notifyListeners();
    }
  }

  void deleteStation(String stationId) {
    _stations.removeWhere((station) => station.id == stationId);
    notifyListeners();
  }

  void updateStationStatus(String stationId, StationStatus status) {
    final index = _stations.indexWhere((s) => s.id == stationId);
    if (index != -1) {
      final station = _stations[index];
      _stations[index] = ChargingStation(
        id: station.id,
        name: station.name,
        address: station.address,
        latitude: station.latitude,
        longitude: station.longitude,
        pricePerKwh: station.pricePerKwh,
        status: status,
        connectorTypes: station.connectorTypes,
        powerKw: station.powerKw,
      );
      notifyListeners();
    }
  }

  void updateStationPrice(String stationId, double newPrice) {
    final index = _stations.indexWhere((s) => s.id == stationId);
    if (index != -1) {
      final station = _stations[index];
      _stations[index] = ChargingStation(
        id: station.id,
        name: station.name,
        address: station.address,
        latitude: station.latitude,
        longitude: station.longitude,
        pricePerKwh: newPrice,
        status: station.status,
        connectorTypes: station.connectorTypes,
        powerKw: station.powerKw,
      );
      notifyListeners();
    }
  }

  void bulkUpdateStationPrices(List<String> stationIds, double newPrice) {
    for (final id in stationIds) {
      updateStationPrice(id, newPrice);
    }
  }

  void bulkUpdateStationPricesByPercentage(List<String> stationIds, double percentage) {
    for (final id in stationIds) {
      final index = _stations.indexWhere((s) => s.id == id);
      if (index != -1) {
        final station = _stations[index];
        final newPrice = station.pricePerKwh * (1 + percentage / 100);
        updateStationPrice(id, newPrice);
      }
    }
  }

  void bulkUpdateStationStatus(List<String> stationIds, StationStatus status) {
    for (final id in stationIds) {
      updateStationStatus(id, status);
    }
  }

  // Add these new service management methods
  Future<void> addService(Service service) async {
    // In a real app, this would make an API call
    // For now, we'll just add it to our local list
    final newService = Service(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: service.name,
      description: service.description,
      price: service.price,
      imageUrl: service.imageUrl,
    );
    
    _services.add(newService);
    notifyListeners();
  }

  Future<void> updateService(Service service) async {
    // In a real app, this would make an API call
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _services[index] = service;
      notifyListeners();
    }
  }

  Future<void> removeService(String id) async {
    // In a real app, this would make an API call
    _services.removeWhere((service) => service.id == id);
    notifyListeners();
  }

  // Add these new store management methods
  Future<void> updateStore(Store store) async {
    // In a real app, this would make an API call
    _store = store;
    notifyListeners();
  }

  Future<void> removeStore() async {
    // In a real app, this would make an API call
    _store = null;
    notifyListeners();
  }

  Future<void> addStore(Store store) async {
    // In a real app, this would make an API call
    _store = store;
    notifyListeners();
  }

  // Add these new product management methods
  Future<void> createProduct(Product product) async {
    // In a real app, this would make an API call
    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: product.name,
      description: product.description,
      price: product.price,
      stockQuantity: product.stockQuantity,
      imageUrl: product.imageUrl,
      category: product.category,
    );
    
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> editProduct(Product product) async {
    // In a real app, this would make an API call
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    // In a real app, this would make an API call
    _products.removeWhere((product) => product.id == id);
    notifyListeners();
  }

  // Additional helper methods for product management
  Future<void> updateProductStock(String id, int newStock) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final product = _products[index];
      _products[index] = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        stockQuantity: newStock,
        imageUrl: product.imageUrl,
        category: product.category,
      );
      notifyListeners();
    }
  }

  Future<void> updateProductPrice(String id, double newPrice) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final product = _products[index];
      _products[index] = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: newPrice,
        stockQuantity: product.stockQuantity,
        imageUrl: product.imageUrl,
        category: product.category,
      );
      notifyListeners();
    }
  }

  // Add these new location management methods
  Future<void> updateLocation(StoreLocation location) async {
    // In a real app, this would make an API call
    _location = location;
    notifyListeners();
  }

  Future<void> removeLocation() async {
    // In a real app, this would make an API call
    _location = null;
    notifyListeners();
  }

  Future<void> addLocation(StoreLocation location) async {
    // In a real app, this would make an API call
    _location = location;
    notifyListeners();
  }
}