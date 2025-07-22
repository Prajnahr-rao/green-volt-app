import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/product.dart';
import '../models/service.dart';
import '../models/location.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Use localhost for web
    }
    return 'http://10.0.2.2:3000'; // Use 10.0.2.2 for Android emulator
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest error')) {
        throw Exception('Cannot connect to server. Please ensure the backend is running.');
      }
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Get all users
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to load users');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest error')) {
        throw Exception('Cannot connect to server. Please ensure the backend is running.');
      }
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Create a new user
  Future<Map<String, dynamic>> createUser(String name, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: json.encode({'name': name, 'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest error')) {
        throw Exception('Cannot connect to server. Please ensure the backend is running.');
      }
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Login user
  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User(
          id: data['id'].toString(),
          name: data['name'],
          email: data['email'],
          role: _parseUserRole(data['role']),
          dateJoined: DateTime.parse(data['created_at']),
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest error')) {
        throw Exception('Cannot connect to server. Please ensure the backend is running.');
      }
      throw Exception('Error: ${e.toString()}');
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

  // Product Management APIs
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();

        // Add mock categories if they don't exist
        final categories = ['Chargers', 'Adapters', 'Cables', 'Accessories'];
        for (int i = 0; i < products.length; i++) {
          products[i].category = categories[i % categories.length];
        }

        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      // For demo purposes, return mock products if API fails
      return _getMockProducts();
    }
  }

  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'Fast Charging Cable',
        description: 'High-speed charging cable compatible with all EV models',
        price: 29.99,
        imageUrl: 'https://images.unsplash.com/photo-1617704116488-caaabac2d34e?w=500',
        category: 'Cables',
        stockQuantity: 45,
      ),
      Product(
        id: '2',
        name: 'Wall Charger',
        description: 'Home wall charging station with smart features',
        price: 499.99,
        imageUrl: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=500',
        category: 'Chargers',
        stockQuantity: 12,
      ),
      Product(
        id: '3',
        name: 'Travel Adapter Kit',
        description: 'Universal adapter kit for charging while traveling',
        price: 79.99,
        imageUrl: 'https://images.unsplash.com/photo-1558427400-bc691467a8a9?w=500',
        category: 'Adapters',
        stockQuantity: 30,
      ),
      Product(
        id: '4',
        name: 'Charging Port Cover',
        description: 'Protective cover for your vehicle charging port',
        price: 19.99,
        imageUrl: 'https://images.unsplash.com/photo-1581092921461-7031e8fbc6e5?w=500',
        category: 'Accessories',
        stockQuantity: 100,
      ),
    ];
  }

  Future<Product> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add product');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/${product.id}'),
        headers: _headers,
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Service Management APIs
  Future<List<Service>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final services = data.map((json) => Service.fromJson(json)).toList();

        // Add mock categories if they don't exist
        final categories = ['Maintenance', 'Repair', 'Inspection', 'Installation'];
        for (int i = 0; i < services.length; i++) {
          services[i].category = categories[i % categories.length];
        }

        return services;
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      // For demo purposes, return mock services if API fails
      return _getMockServices();
    }
  }

  List<Service> _getMockServices() {
    return [
      Service(
        id: '1',
        name: 'Battery Health Check',
        description: 'Comprehensive battery health assessment and diagnostics',
        price: 49.99,
        imageUrl: 'https://images.unsplash.com/photo-1581092921461-7031e8fbc6e5?w=500',
        category: 'Inspection',
      ),
      Service(
        id: '2',
        name: 'Charging System Repair',
        description: 'Repair and maintenance of EV charging systems',
        price: 129.99,
        imageUrl: 'https://images.unsplash.com/photo-1558427400-bc691467a8a9?w=500',
        category: 'Repair',
      ),
      Service(
        id: '3',
        name: 'Home Charger Installation',
        description: 'Professional installation of home EV charging stations',
        price: 299.99,
        imageUrl: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=500',
        category: 'Installation',
      ),
      Service(
        id: '4',
        name: 'Annual Maintenance',
        description: 'Complete annual maintenance service for your electric vehicle',
        price: 199.99,
        imageUrl: 'https://images.unsplash.com/photo-1597766353939-ebafc77b9a36?w=500',
        category: 'Maintenance',
      ),
    ];
  }

  Future<Service> addService(Service service) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/services'),
        headers: _headers,
        body: json.encode(service.toJson()),
      );

      if (response.statusCode == 201) {
        return Service.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add service');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<Service> updateService(Service service) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/services/${service.id}'),
        headers: _headers,
        body: json.encode(service.toJson()),
      );

      if (response.statusCode == 200) {
        return Service.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update service');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete service');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Location Management APIs
  Future<List<StoreLocation>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => StoreLocation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<StoreLocation> addLocation(StoreLocation location) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: _headers,
        body: json.encode(location.toJson()),
      );

      if (response.statusCode == 201) {
        return StoreLocation.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add location');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<StoreLocation> updateLocation(StoreLocation location) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/locations/${location.id}'),
        headers: _headers,
        body: json.encode(location.toJson()),
      );

      if (response.statusCode == 200) {
        return StoreLocation.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/locations/$locationId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete location');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Update user
  Future<Map<String, dynamic>> updateUser(String userId, {
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update user');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest error')) {
        throw Exception('Cannot connect to server. Please ensure the backend is running.');
      }
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest error')) {
        throw Exception('Cannot connect to server. Please ensure the backend is running.');
      }
      throw Exception('Error: ${e.toString()}');
    }
  }
}
