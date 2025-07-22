import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/models/station.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/models/location.dart';
import 'package:flutter_application_1/screens/booking_confirmation_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/map_content_wrapper.dart';
import 'package:flutter_application_1/screens/map_screen.dart';
import 'package:flutter_application_1/screens/notifications_screen.dart';
import 'package:flutter_application_1/screens/payment_screen.dart';
import 'package:flutter_application_1/screens/payment_confirmation_screen.dart';
import 'package:flutter_application_1/screens/user_settings_screen.dart';
import 'package:flutter_application_1/screens/service_booking_confirmation_screen.dart';
import 'package:flutter_application_1/screens/order_confirmation_screen.dart';
import 'package:flutter_application_1/services/api_service.dart';
import '../models/user.dart';
import '../providers/admin_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'package:provider/provider.dart';
import '../models/charging_station.dart';
import '../models/vehicle.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final User currentUser;

  const HomeScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedFilter = 'All';
  int _unreadNotificationsCount = 2; // Mock count, in a real app this would be fetched from a service
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Orders section state variables
  String _selectedOrderStatus = 'All';
  String _orderSearchQuery = '';

  // Mock data for nearby stations
  final List<Map<String, dynamic>> _nearbyStations = [
    {
      'name': 'Green Volt Station #1',
      'distance': '0.5 km',
      'type': 'DC Fast Charger',
      'available': true,
      'price': '\$0.35/kWh',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'City Center EV Hub',
      'distance': '1.2 km',
      'type': 'Level 2 Charger',
      'available': true,
      'price': '\$0.25/kWh',
      'rating': 4.5,
      'image': 'https://images.unsplash.com/photo-1558427400-bc691467a8a9?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'Westside Mall Charging',
      'distance': '2.3 km',
      'type': 'DC Fast Charger',
      'available': false,
      'price': '\$0.40/kWh',
      'rating': 4.2,
      'image': 'https://images.unsplash.com/photo-1568605118966-5a3e2c3e0a5d?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'Downtown Supercharger',
      'distance': '3.1 km',
      'type': 'Tesla Supercharger',
      'available': true,
      'price': '\$0.45/kWh',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1558427400-bc691467a8a9?q=80&w=300&auto=format&fit=crop',
    },
  ];

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _products = [];
  List<Service> _services = [];
  List<StoreLocation> _locations = [];
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(12.9716, 77.5946); // Default to Bangalore

  // Mock vehicle for testing
  final Vehicle _mockVehicle = Vehicle(
    id: '1',
    make: 'Tesla',
    model: 'Model 3',
    licensePlate: 'EV123',
    batteryCapacity: '75',
    chargerType: 'Type 2',
    imageUrl: 'assets/images/tesla_model3.png',
    year: 2022,
  );

  Future<Map<String, dynamic>?> _showTimeSlotPicker(BuildContext context, {ChargingStation? station}) async {
    // Use current date and time as defaults
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Default values if station is not provided
    int selectedDuration = 30; // Default 30 minutes
    double costPerKwh = station?.pricePerKwh ?? 0.35; // Use station price if available
    double powerKw = station?.powerKw ?? 50; // Use station power if available

    // Get available durations from station or use defaults
    List<int> availableDurations = station?.availableDurations ?? [30, 60, 90, 120];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        double costForDuration = (costPerKwh * powerKw * selectedDuration) / 60;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Book ${station?.name ?? 'Charging Station'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Station info if available
                  if (station != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.ev_station, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  station.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Duration'),
                    subtitle: Text('$selectedDuration minutes'),
                    trailing: DropdownButton<int>(
                      value: selectedDuration,
                      items: availableDurations.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value min'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedDuration = newValue;
                            costForDuration = (costPerKwh * powerKw * selectedDuration) / 60;
                          });
                        }
                      },
                    ),
                  ),

                  // Charger type selection if station has multiple types
                  if (station != null && station.availableChargerTypes.length > 1)
                    ListTile(
                      title: const Text('Charger Type'),
                      subtitle: Wrap(
                        spacing: 8,
                        children: station.availableChargerTypes.map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: true,
                            onSelected: (bool selected) {
                              // In a real app, this would update the selected charger type
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  const Divider(),

                  // Cost breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rate:'),
                            Text('\$${costPerKwh.toStringAsFixed(2)}/kWh'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Power:'),
                            Text('${powerKw.toStringAsFixed(0)} kW'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duration:'),
                            Text('$selectedDuration min'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estimated Cost:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${costForDuration.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    // Create booking details
                    final bookingDetails = {
                      'date': selectedDate,
                      'time': selectedTime,
                      'duration': selectedDuration,
                      'cost': costForDuration,
                      'station': station,
                    };

                    // Show payment screen with dynamic values
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          initialAmount: costForDuration,
                          description: 'Charging session at ${station?.name ?? 'Charging Station'}',
                          stationId: station?.id ?? '',
                          stationName: station?.name ?? '',
                          transactionType: TransactionType.charging,
                          onPaymentSuccess: (double amount, String transactionId, String paymentMethod) {
                            // Show payment confirmation
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => PaymentConfirmationScreen(
                                  amount: amount,
                                  transactionId: transactionId,
                                  paymentDate: DateTime.now(),
                                  paymentMethod: paymentMethod,
                                  onContinue: () {
                                    // Navigate to booking confirmation with dynamic station data
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => BookingConfirmationScreen(
                                          station: station is Station ? station as Station : Station(
                                            id: '',
                                            name: 'Charging Station',
                                            address: '',
                                            latitude: 0,
                                            longitude: 0,
                                            imageUrl: '',
                                            availableChargerTypes: ['Type 2'],
                                            totalChargers: 1,
                                            availableChargers: 1,
                                            rating: 0,
                                            reviewCount: 0,
                                            amenities: [],
                                            operatingHours: '',
                                            available: true,
                                            type: 'EV Charger',
                                            distance: '',
                                            price: '$costPerKwh/kWh',
                                            vehicle: _mockVehicle
                                          ),
                                          selectedDate: selectedDate,
                                          startTime: selectedTime,
                                          durationMinutes: selectedDuration,
                                          vehicle: _mockVehicle,
                                          chargerType: station is Station && (station as Station).availableChargerTypes.isNotEmpty ?
                                              (station as Station).availableChargerTypes[0] : 'Type 2',
                                          chargerNumber: 1,
                                          paymentMethod: paymentMethod,
                                          transactionId: transactionId,
                                          amount: amount,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Proceed to Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChargingStation> _getFilteredStations(List<ChargingStation> stations) {
    // First apply category filter if not 'All'
    var filteredStations = stations;
    if (_selectedFilter != 'All') {
      // This is a simplified example - in a real app, you would have a category field in your model
      filteredStations = stations.where((station) {
        // Match station type with filter
        if (_selectedFilter == 'Fast Charging' && station.powerKw >= 50) {
          return true;
        } else if (_selectedFilter == 'Standard Charging' && station.powerKw < 50) {
          return true;
        }
        // Match connector types
        for (var type in station.availableChargerTypes) {
          if (type.contains(_selectedFilter)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // Then apply search query if not empty
    if (_searchQuery.isEmpty) {
      return filteredStations;
    }

    final query = _searchQuery.toLowerCase();
    return filteredStations.where((station) {
      return station.name.toLowerCase().contains(query) ||
             station.address.toLowerCase().contains(query);
    }).toList();
  }

  List<Service> _getFilteredServices() {
    // First apply category filter if not 'All'
    var filteredServices = _services;
    if (_selectedFilter != 'All') {
      filteredServices = _services.where((service) {
        return service.category.contains(_selectedFilter);
      }).toList();
    }

    // Then apply search query if not empty
    if (_searchQuery.isEmpty) {
      return filteredServices;
    }

    final query = _searchQuery.toLowerCase();
    return filteredServices.where((service) {
      return service.name.toLowerCase().contains(query) ||
             service.description.toLowerCase().contains(query) ||
             service.category.toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    // First apply category filter if not 'All'
    var filteredProducts = _products;
    if (_selectedFilter != 'All') {
      filteredProducts = _products.where((product) {
        return (product['category'] as String?)?.contains(_selectedFilter) ?? false;
      }).toList();
    }

    // Then apply search query if not empty
    if (_searchQuery.isEmpty) {
      return filteredProducts;
    }

    final query = _searchQuery.toLowerCase();
    return filteredProducts.where((product) {
      return (product['name'] as String).toLowerCase().contains(query) ||
             (product['description'] as String).toLowerCase().contains(query) ||
             ((product['category'] as String?)?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts();
      final services = await _apiService.getServices();
      final locations = await _apiService.getLocations();

      if (mounted) {
        setState(() {
          _products = products.map((product) => {
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'category': product.category,
            'stockQuantity': product.stockQuantity,
          }).toList();
          _services = services;
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final filteredStations = _getFilteredStations(adminProvider.stations);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            // Removed static image from AppBar title. Leaving title blank for now.
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      ).then((value) {
                        // When returning from notifications screen, update the unread count
                        // In a real app, this would be handled by a state management solution
                        setState(() {
                          _unreadNotificationsCount = 0;
                        });
                      });
                    },
                  ),
                  if (_unreadNotificationsCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$_unreadNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {},
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.green),
                  accountName: Text(widget.currentUser.name),
                  accountEmail: Text(widget.currentUser.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSettingsScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/help');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support),
                  title: const Text('Contact'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/contact');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    // Navigate to login screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false, // Remove all previous routes
                    );
                  },
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(),
              const MapContentWrapper(),
              _buildProductsSection(),
              _buildServicesSection(),
              _buildOrdersContent(),
              _buildPaymentsContent(),
            ],
          ),
          floatingActionButton: _cartItems.isNotEmpty ? Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    _showCartDialog();
                  },
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text('Cart (${_cartItems.length})'),
                  elevation: 4,
                ),
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ) : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: _selectedIndex == 0
                    ? const Icon(Icons.home, size: 35)
                    : const Icon(Icons.home_outlined),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                label: 'Map',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.production_quantity_limits), //miscellaneous_services_outlined
                label: 'Products',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.design_services_outlined), //miscellaneous_services_outlined
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 4
                    ? const Icon(Icons.receipt_long, size: 28)
                    : const Icon(Icons.receipt_long_outlined),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 5
                    ? const Icon(Icons.account_balance_wallet, size: 28)
                    : const Icon(Icons.account_balance_wallet_outlined),
                label: 'Payments',
              ),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final stations = _getFilteredStations(adminProvider.stations);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          widget.currentUser.name.isNotEmpty
                              ? widget.currentUser.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                              : '',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.currentUser.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main heading
                const Text(
                  'Find Your Charging Station',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by location or station name',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.green),
                        onPressed: () {
                          // Show filter options
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Nearby stations section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Charging Stations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1; // Switch to map tab
                        });
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Station list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return _buildStationCard(station);
                  },
                ),

                const SizedBox(height: 24),

                // Plan your route button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Plan Your Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick stats section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total Charges', '27', Icons.battery_charging_full),
                      _buildStatItem('CO₂ Saved', '245 kg', Icons.eco),
                      _buildStatItem('Favorite Stations', '3', Icons.favorite),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with user info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.shopping_bag,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Our Products',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Shop Quality EV Accessories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main heading
            const Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  // Filter products based on search
                },
              ),
            ),

            const SizedBox(height: 20),

            // Categories section
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Category chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('All', isSelected: _selectedFilter == 'All'),
                  _buildCategoryChip('Chargers', isSelected: _selectedFilter == 'Chargers'),
                  _buildCategoryChip('Adapters', isSelected: _selectedFilter == 'Adapters'),
                  _buildCategoryChip('Cables', isSelected: _selectedFilter == 'Cables'),
                  _buildCategoryChip('Accessories', isSelected: _selectedFilter == 'Accessories'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Products section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all products
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Products grid
            _products.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No products available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _getFilteredProducts().length,
                    itemBuilder: (context, index) {
                      final product = _getFilteredProducts()[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image with stack for discount badge
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    product['imageUrl'],
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 140,
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 50),
                                      );
                                    },
                                  ),
                                ),
                                // Price tag
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '\$${product['price'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                // Discount badge if applicable
                                if (index % 3 == 0)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '15% OFF',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Product details
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product['description'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Category
                                  Row(
                                    children: [
                                      Icon(Icons.category, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        product['category'] ?? 'General',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Stock and rating
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Stock: ${product['stockQuantity']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: product['stockQuantity'] > 10
                                              ? Colors.green
                                              : product['stockQuantity'] > 0
                                                  ? Colors.orange
                                                  : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.star, color: Colors.amber, size: 14),
                                      Text(
                                        ' ${(3.5 + (index % 3) * 0.5).toStringAsFixed(1)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                                      label: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: product['stockQuantity'] > 0 ? Colors.orange : Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      // Disable button if out of stock
                                      onPressed: product['stockQuantity'] <= 0 ? null : () {
                                        // Check if product is in stock
                                        if (product['stockQuantity'] <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Sorry, this product is out of stock'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          int existingIndex = _cartItems.indexWhere(
                                              (item) => item['name'] == product['name']);

                                          // Check if adding more would exceed available stock
                                          if (existingIndex >= 0) {
                                            int currentQty = _cartItems[existingIndex]['quantity'] ?? 1;
                                            if (currentQty >= product['stockQuantity']) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Sorry, only ${product['stockQuantity']} items available in stock'),
                                                  backgroundColor: Colors.orange,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                              return;
                                            }

                                            _cartItems[existingIndex]['quantity'] = currentQty + 1;
                                          } else {
                                            final cartItem = Map<String, dynamic>.from(product);
                                            cartItem['quantity'] = 1;
                                            cartItem['isService'] = false;
                                            cartItem['id'] = product['id'] ?? '';
                                            _cartItems.add(cartItem);
                                          }

                                          _updateCartItemCount();
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product['name']} added to cart'),
                                            duration: const Duration(seconds: 2),
                                            action: SnackBarAction(
                                              label: 'VIEW CART',
                                              onPressed: () {
                                                _showCartDialog();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),

            // Special offers section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade300, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Special Offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Get 20% off on all charging accessories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use code: CHARGE20',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_offer,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.orange,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              // Update the selected filter for products
              _selectedFilter = label;
              // Reset search query when changing filters for better UX
              _searchQuery = '';
            });
          }
        },
      ),
    );
  }

  Widget _buildServicesSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with user info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.design_services,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Our Services',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Professional EV Maintenance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main heading
            const Text(
              'Featured Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Service categories section
            const Text(
              'Service Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Service category chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildServiceCategoryChip('All', isSelected: _selectedFilter == 'All'),
                  _buildServiceCategoryChip('Maintenance', isSelected: _selectedFilter == 'Maintenance'),
                  _buildServiceCategoryChip('Repair', isSelected: _selectedFilter == 'Repair'),
                  _buildServiceCategoryChip('Inspection', isSelected: _selectedFilter == 'Inspection'),
                  _buildServiceCategoryChip('Installation', isSelected: _selectedFilter == 'Installation'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Popular services section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all services
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Services list
            _services.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.design_services_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No services available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getFilteredServices().length,
                    itemBuilder: (context, index) {
                      final service = _getFilteredServices()[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Show service details
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Service image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    service.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Service details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              service.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '\$${service.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        service.description,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Service rating
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 16),
                                              Text(
                                                ' ${(4.0 + (index % 2) * 0.5).toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const Spacer(),
                                          // Add to cart button
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                int existingIndex = _cartItems.indexWhere(
                                                    (item) => item['name'] == service.name);

                                                if (existingIndex >= 0) {
                                                  _cartItems[existingIndex]['quantity'] =
                                                      (_cartItems[existingIndex]['quantity'] ?? 1) + 1;
                                                } else {
                                                  final cartItem = {
                                                    'id': service.id ?? '',
                                                    'name': service.name,
                                                    'price': service.price,
                                                    'description': service.description,
                                                    'category': service.category,
                                                    'imageUrl': service.imageUrl,
                                                    'quantity': 1,
                                                    'isService': true
                                                  };
                                                  _cartItems.add(cartItem);
                                                }

                                                _updateCartItemCount();
                                              });

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${service.name} added to cart'),
                                                  duration: const Duration(seconds: 2),
                                                  action: SnackBarAction(
                                                    label: 'VIEW CART',
                                                    onPressed: () {
                                                      _showCartDialog();
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                                            label: const Text('Book', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),

            // Promotion section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Service Package',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Complete EV Health Check',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Book now and get 15% off',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.health_and_safety,
                      color: Colors.blue.shade600,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategoryChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              // Update the selected filter
              _selectedFilter = label;
              // Reset search query when changing filters for better UX
              _searchQuery = '';
            });
          }
        },
      ),
    );
  }

  Widget _buildOrdersContent() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Get all transactions
        final allTransactions = transactionProvider.transactions;

        // State variables for filtering
        final selectedStatus = _selectedOrderStatus;
        final searchQuery = _orderSearchQuery.toLowerCase();

        // Filter transactions to show orders (products, services, and station bookings)
        final allOrders = allTransactions.where((transaction) =>
          transaction.type == TransactionType.product ||
          transaction.type == TransactionType.service ||
          transaction.type == TransactionType.charging).toList();

        // Apply status filter if not 'All'
        var filteredOrders = allOrders;
        if (selectedStatus != 'All') {
          TransactionStatus statusFilter;
          switch (selectedStatus) {
            case 'Pending':
              statusFilter = TransactionStatus.pending;
              break;
            case 'Completed':
              statusFilter = TransactionStatus.completed;
              break;
            case 'Cancelled':
              statusFilter = TransactionStatus.failed;
              break;
            case 'Refunded':
              statusFilter = TransactionStatus.refunded;
              break;
            default:
              statusFilter = TransactionStatus.completed;
          }
          filteredOrders = allOrders.where((order) => order.status == statusFilter).toList();
        }

        // Apply search filter if search query is not empty
        if (searchQuery.isNotEmpty) {
          filteredOrders = filteredOrders.where((order) =>
            order.title.toLowerCase().contains(searchQuery) ||
            order.description.toLowerCase().contains(searchQuery) ||
            (order.productName?.toLowerCase().contains(searchQuery) ?? false) ||
            (order.serviceName?.toLowerCase().contains(searchQuery) ?? false) ||
            (order.stationName?.toLowerCase().contains(searchQuery) ?? false) ||
            order.type.toString().toLowerCase().contains(searchQuery) ||
            order.paymentMethod.toLowerCase().contains(searchQuery)
          ).toList();
        }

        // Sort orders by date (newest first)
        filteredOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Separate active and past orders
        final activeOrders = filteredOrders.where((order) =>
          order.status == TransactionStatus.pending).toList();

        final pastOrders = filteredOrders.where((order) =>
          order.status != TransactionStatus.pending).toList();

        // Calculate total spent on orders
        final totalSpent = allOrders
            .where((order) => !order.isCredit)
            .fold(0.0, (sum, order) => sum + order.amount);

        // Calculate order statistics
        final completedCount = allOrders
            .where((order) => order.status == TransactionStatus.completed)
            .length;

        final pendingCount = allOrders
            .where((order) => order.status == TransactionStatus.pending)
            .length;

        final refundedCount = allOrders
            .where((order) => order.status == TransactionStatus.refunded)
            .length;

        // Calculate transaction type counts
        final productCount = allOrders
            .where((order) => order.type == TransactionType.product)
            .length;

        final serviceCount = allOrders
            .where((order) => order.type == TransactionType.service)
            .length;

        final chargingCount = allOrders
            .where((order) => order.type == TransactionType.charging)
            .length;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section with user info
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.purple.shade100,
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.purple.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Orders',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${allOrders.length} Orders & Bookings',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main heading
                const Text(
                  'Track Your Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: const Icon(Icons.search, color: Colors.purple),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _orderSearchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Order status filter
                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Status filter chips
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildOrderStatusChip('All', isSelected: _selectedOrderStatus == 'All'),
                      _buildOrderStatusChip('Pending', isSelected: _selectedOrderStatus == 'Pending'),
                      _buildOrderStatusChip('Completed', isSelected: _selectedOrderStatus == 'Completed'),
                      _buildOrderStatusChip('Cancelled', isSelected: _selectedOrderStatus == 'Cancelled'),
                      _buildOrderStatusChip('Refunded', isSelected: _selectedOrderStatus == 'Refunded'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Active Orders Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Active Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // View all active orders
                        setState(() {
                          _selectedOrderStatus = 'Pending';
                        });
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Active Orders List
                if (transactionProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                    ),
                  )
                else if (activeOrders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No active orders found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 2; // Navigate to Products tab
                              });
                            },
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text('Browse Products'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...activeOrders.take(2).map((transaction) => _buildOrderItem(transaction)).toList(),

                const SizedBox(height: 24),

                // Order History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Order History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$completedCount',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (refundedCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$refundedCount',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to full order history
                        setState(() {
                          _selectedOrderStatus = 'Completed';
                        });
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Past Orders List (showing completed/cancelled orders)
                if (pastOrders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No past orders found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...pastOrders.take(3).map((transaction) => _buildOrderItem(transaction, isHistory: true)).toList(),

                const SizedBox(height: 24),

                // Transaction type summary
                const Text(
                  'Transaction Types',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Transaction type cards
                Row(
                  children: [
                    Expanded(
                      child: _buildTransactionTypeCard(
                        'Products',
                        productCount,
                        Icons.shopping_bag,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTransactionTypeCard(
                        'Services',
                        serviceCount,
                        Icons.build,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTransactionTypeCard(
                        'Stations',
                        chargingCount,
                        Icons.ev_station,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Order summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade300, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Total Spent on Orders',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalSpent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Colors.purple.shade600,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.purple,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedOrderStatus = label;
              // Reset search query when changing filters for better UX
              _orderSearchQuery = '';
            });
          }
        },
      ),
    );
  }

  Widget _buildOrderItem(Transaction transaction, {bool isHistory = false}) {
    // Determine the status color
    Color statusColor;
    switch (transaction.status) {
      case TransactionStatus.completed:
        statusColor = Colors.green;
        break;
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        break;
      case TransactionStatus.failed:
        statusColor = Colors.red;
        break;
      case TransactionStatus.refunded:
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Get transaction type color
    Color typeColor;
    switch (transaction.type) {
      case TransactionType.product:
        typeColor = Colors.orange;
        break;
      case TransactionType.service:
        typeColor = Colors.blue;
        break;
      case TransactionType.charging:
        typeColor = Colors.green;
        break;
      case TransactionType.refund:
        typeColor = Colors.purple;
        break;
      case TransactionType.reward:
        typeColor = Colors.amber;
        break;
      default:
        typeColor = Colors.grey;
    }

    // Get transaction date in a more readable format
    final formattedDate = transaction.formattedDate;

    // Get transaction amount
    final amount = transaction.formattedAmount;

    // Get transaction ID
    final transactionId = transaction.id;

    // Get payment method with proper formatting
    final paymentMethod = _formatPaymentMethod(transaction.paymentMethod);

    // Get transaction status
    final status = _formatStatus(transaction.status);

    // Extract booking time for station bookings
    DateTime? bookingTime;
    if (transaction.type == TransactionType.charging) {
      final regex = RegExp(r'for (\d{4}-\d{2}-\d{2} \d{2}:\d{2})');
      final match = regex.firstMatch(transaction.description);

      if (match != null && match.groupCount >= 1) {
        try {
          bookingTime = DateTime.parse(match.group(1)!);
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showTransactionDetails(transaction);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type indicator
            Container(
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(transaction.icon, color: typeColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _formatTransactionType(transaction.type),
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name section
                  if (transaction.type == TransactionType.product && transaction.productName != null)
                    _buildItemNameSection(
                      'Product',
                      transaction.productName!,
                      Icons.shopping_bag,
                      Colors.orange,
                    )
                  else if (transaction.type == TransactionType.service && transaction.serviceName != null)
                    _buildItemNameSection(
                      'Service',
                      transaction.serviceName!,
                      Icons.build,
                      Colors.blue,
                    )
                  else if (transaction.type == TransactionType.charging && transaction.stationName != null)
                    _buildItemNameSection(
                      'Station',
                      transaction.stationName!,
                      Icons.ev_station,
                      Colors.green,
                    )
                  else
                    _buildItemNameSection(
                      'Item',
                      transaction.title,
                      transaction.icon,
                      typeColor,
                    ),

                  const SizedBox(height: 12),

                  // Date and payment info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    paymentMethod,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Amount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: transaction.isCredit ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: transaction.isCredit ? Colors.green.shade200 : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          amount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: transaction.isCredit ? Colors.green : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Booking time for station bookings
                  if (bookingTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking Time',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(bookingTime),
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (bookingTime.isAfter(DateTime.now()))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Upcoming',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Passed',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Description
                  if (transaction.description.isNotEmpty &&
                      !transaction.description.contains('for 20') && // Skip if it contains booking time format
                      transaction.description != 'Payment processed')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        transaction.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_canCancelTransaction(transaction))
                          ElevatedButton.icon(
                            onPressed: () {
                              _showCancelOrderDialog(transaction);
                            },
                            icon: const Icon(Icons.cancel, size: 16),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            _showTransactionDetails(transaction);
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemNameSection(String label, String name, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsContent() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Format currency values
        final totalSpent = '\$${transactionProvider.totalSpentThisMonth.toStringAsFixed(2)}';
        final chargingSpent = '\$${transactionProvider.chargingSpentThisMonth.toStringAsFixed(2)}';
        final productsSpent = '\$${transactionProvider.productsSpentThisMonth.toStringAsFixed(2)}';
        final servicesSpent = '\$${transactionProvider.servicesSpentThisMonth.toStringAsFixed(2)}';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.account_balance_wallet, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Total Spent This Month',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalSpent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPaymentStat('Charging', chargingSpent),
                          _buildPaymentStat('Products', productsSpent),
                          _buildPaymentStat('Services', servicesSpent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Transaction History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to full transaction history
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transaction List
                if (transactionProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (transactionProvider.recentTransactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No transactions found'),
                    ),
                  )
                else
                  ...transactionProvider.recentTransactions.map((transaction) =>
                    _buildTransactionItem(
                      transaction: transaction,
                    )
                  ).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }



  Widget _buildTransactionItem({
    required Transaction transaction,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: transaction.isCredit ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction.icon,
            color: transaction.isCredit ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          transaction.formattedDate,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          transaction.formattedAmount,
          style: TextStyle(
            color: transaction.isCredit ? Colors.green : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // Show transaction details
          _showTransactionDetails(transaction);
        },
      ),
    );
  }



  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.green),
            SizedBox(width: 10),
            Text('My Cart'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    final quantity = item['quantity'] as int? ?? 1;
                    final price = item['price'] as double;
                    final totalPrice = quantity * price;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (item['isService'] == true ? Colors.blue : Colors.orange).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['isService'] == true ? Icons.build : Icons.shopping_bag,
                          color: item['isService'] == true ? Colors.blue : Colors.orange
                        ),
                      ),
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('\$${price.toStringAsFixed(2)} × $quantity'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                _cartItems.removeAt(index);
                              });
                              Navigator.pop(context);
                              if (_cartItems.isNotEmpty) {
                                _showCartDialog(); // Reopen dialog to refresh
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (_cartItems.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${_cartItems.fold(0.0, (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int? ?? 1)).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _cartItems.clear();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('CLEAR CART', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // Determine if cart contains products or services
                bool hasProducts = _cartItems.any((item) => item['isService'] != true);
                bool hasServices = _cartItems.any((item) => item['isService'] == true);

                // Set transaction type and description based on cart contents
                TransactionType transactionType;
                String description;
                String? productId;
                String? productName;
                String? serviceId;
                String? serviceName;

                if (hasProducts && !hasServices) {
                  // Only products
                  transactionType = TransactionType.product;

                  // Get the first product for single item purchase or create a summary for multiple items
                  if (_cartItems.length == 1) {
                    final product = _cartItems[0];
                    productId = product['id']?.toString() ?? 'P001';
                    productName = product['name'];
                    description = 'Purchase: ${product['name']}';
                  } else {
                    productId = 'MULTI';
                    productName = '${_cartItems.length} Products';
                    description = 'Purchase of ${_cartItems.length} products';
                  }
                } else if (hasServices && !hasProducts) {
                  // Only services
                  transactionType = TransactionType.service;

                  // Get the first service for single item booking or create a summary for multiple items
                  if (_cartItems.length == 1) {
                    final service = _cartItems[0];
                    serviceId = service['id']?.toString() ?? 'S001';
                    serviceName = service['name'];
                    description = 'Service: ${service['name']}';
                  } else {
                    serviceId = 'MULTI';
                    serviceName = '${_cartItems.length} Services';
                    description = 'Booking of ${_cartItems.length} services';
                  }
                } else {
                  // Mixed cart
                  transactionType = TransactionType.product; // Default to product for mixed cart

                  // Count products and services
                  int productCount = _cartItems.where((item) => item['isService'] != true).length;
                  int serviceCount = _cartItems.where((item) => item['isService'] == true).length;

                  productId = 'MIXED';
                  productName = '$productCount Products & $serviceCount Services';
                  description = 'Purchase of $productCount products and $serviceCount services';
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      initialAmount: _calculateTotal(),
                      description: description,
                      productId: productId,
                      productName: productName,
                      serviceId: serviceId,
                      serviceName: serviceName,
                      transactionType: transactionType,
                      onPaymentSuccess: (amount, transactionId, paymentMethod) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentConfirmationScreen(
                              amount: amount,
                              transactionId: transactionId,
                              paymentDate: DateTime.now(),
                              paymentMethod: paymentMethod,
                              stationName: transactionType == TransactionType.charging ? productName : null,
                              serviceName: transactionType == TransactionType.service ? serviceName : null,
                              productName: transactionType == TransactionType.product ? productName : null,
                              onContinue: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OrderConfirmationScreen(
                                      cartItems: List<Map<String, dynamic>>.from(_cartItems),
                                      amount: amount,
                                      orderDate: DateTime.now(),
                                    ),
                                  ),
                                );
                                setState(() {
                                  _cartItems.clear();
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('CHECKOUT'),
            ),
          ] else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLOSE'),
            ),
        ],
      ),
    );
  }

  void _updateCartItemCount() {
    setState(() {
      // Cart count is just the number of items in the cart
      // No need for a separate count variable
    });
  }

  Widget _buildStationCard(ChargingStation station) {
    return GestureDetector(
      onTap: () {
        if (station.status == StationStatus.available) {
          _showTimeSlotPicker(context, station: station).then((result) {
            if (result != null) {
              // Time slot picker already handles navigation to payment screen
            }
          });
        } else {
          // Show a message that the station is not available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${station.name} is currently ${_getStatusText(station.status).toLowerCase()}. Please select another station.'),
              backgroundColor: _getStationStatusColor(station.status),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Station image or icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _getStationStatusColor(station.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: station.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          station.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.ev_station,
                              color: _getStationStatusColor(station.status),
                              size: 40,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.ev_station,
                        color: _getStationStatusColor(station.status),
                        size: 40,
                      ),
              ),
              const SizedBox(width: 12),
              // Station details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStationStatusColor(station.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(station.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.address,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Station details row
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        // Power
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: Colors.orange, size: 16),
                            Text(
                              ' ${station.powerKw} kW',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        // Price
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, color: Colors.green, size: 16),
                            Text(
                              ' \$${station.pricePerKwh.toStringAsFixed(2)}/kWh',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        // Hours
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: Colors.blue, size: 16),
                            Text(
                              ' ${station.operatingHours}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Connector types
                    if (station.availableChargerTypes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 4,
                          children: station.availableChargerTypes.map((type) {
                            return Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Rating if available
                    if (station.rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            Text(
                              ' ${station.rating.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (station.reviewCount > 0)
                              Text(
                                ' (${station.reviewCount})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                    if (station.status == StationStatus.available)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Tap to book',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.green.shade700,
                            size: 14,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.green,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }



  Color _getStationStatusColor(StationStatus status) {
    switch (status) {
      case StationStatus.available:
        return Colors.green;
      case StationStatus.inUse:
        return Colors.orange;
      case StationStatus.outOfService:
        return Colors.red;
      case StationStatus.underMaintenance:
        return Colors.purple;
    }
  }

  String _getStatusText(StationStatus status) {
    switch (status) {
      case StationStatus.available:
        return 'Available';
      case StationStatus.inUse:
        return 'In Use';
      case StationStatus.outOfService:
        return 'Out of Service';
      case StationStatus.underMaintenance:
        return 'Under Maintenance';
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      if (item['isService'] == true) {
        total += item['price'] as double;
      } else {
        total += (item['price'] as double) * (item['quantity'] as int? ?? 1);
      }
    }
    return total;
  }

  void _showTransactionDetails(Transaction transaction) {
    // Get color based on transaction type
    Color iconColor;
    switch (transaction.type) {
      case TransactionType.product:
        iconColor = Colors.orange;
        break;
      case TransactionType.service:
        iconColor = Colors.blue;
        break;
      case TransactionType.charging:
        iconColor = Colors.green;
        break;
      case TransactionType.refund:
        iconColor = Colors.purple;
        break;
      case TransactionType.reward:
        iconColor = Colors.amber;
        break;
      default:
        iconColor = Colors.grey;
    }

    // Get title based on transaction type
    String detailTitle;
    switch (transaction.type) {
      case TransactionType.product:
        detailTitle = 'Product Order Details';
        break;
      case TransactionType.service:
        detailTitle = 'Service Booking Details';
        break;
      case TransactionType.charging:
        detailTitle = 'Station Booking Details';
        break;
      case TransactionType.refund:
        detailTitle = 'Refund Details';
        break;
      case TransactionType.reward:
        detailTitle = 'Reward Details';
        break;
      default:
        detailTitle = 'Transaction Details';
    }

    // Extract booking time for station bookings
    DateTime? bookingTime;
    if (transaction.type == TransactionType.charging) {
      final regex = RegExp(r'for (\d{4}-\d{2}-\d{2} \d{2}:\d{2})');
      final match = regex.firstMatch(transaction.description);

      if (match != null && match.groupCount >= 1) {
        try {
          bookingTime = DateTime.parse(match.group(1)!);
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        transaction.icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detailTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transaction ID: ${transaction.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(transaction.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _formatStatus(transaction.status),
                        style: TextStyle(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Item details section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Show specific details based on transaction type
                            if (transaction.type == TransactionType.product && transaction.productName != null)
                              _buildDetailItem('Product', transaction.productName!, Icons.shopping_bag, Colors.orange),

                            if (transaction.type == TransactionType.service && transaction.serviceName != null)
                              _buildDetailItem('Service', transaction.serviceName!, Icons.build, Colors.blue),

                            if (transaction.type == TransactionType.charging && transaction.stationName != null)
                              _buildDetailItem('Station', transaction.stationName!, Icons.ev_station, Colors.green),

                            if (transaction.description.isNotEmpty &&
                                !transaction.description.contains('for 20') && // Skip if it contains booking time format
                                transaction.description != 'Payment processed')
                              _buildDetailItem('Description', transaction.description, Icons.description, Colors.grey),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment details section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailItem(
                              'Amount',
                              transaction.formattedAmount,
                              Icons.attach_money,
                              transaction.isCredit ? Colors.green : Colors.grey.shade700,
                            ),
                            _buildDetailItem(
                              'Payment Method',
                              _formatPaymentMethod(transaction.paymentMethod),
                              Icons.payment,
                              Colors.blue,
                            ),
                            _buildDetailItem(
                              'Transaction Date',
                              transaction.formattedDate,
                              Icons.calendar_today,
                              Colors.purple,
                            ),
                            if (transaction.transactionReference != null &&
                                transaction.transactionReference != transaction.id)
                              _buildDetailItem(
                                'Reference',
                                transaction.transactionReference!,
                                Icons.link,
                                Colors.teal,
                              ),
                          ],
                        ),
                      ),

                      // Booking time section for station bookings
                      if (bookingTime != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 20, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Booking Time',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (bookingTime.isAfter(DateTime.now()))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Upcoming',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Passed',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event, color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE, MMMM d, yyyy').format(bookingTime),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('h:mm a').format(bookingTime),
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_canCancelTransaction(transaction))
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCancelOrderDialog(transaction);
                        },
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('CANCEL ORDER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.refunded:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI Payment';
      case 'cash':
        return 'Cash Payment';
      case 'reward':
        return 'Reward Points';
      default:
        return method;
    }
  }

  String _formatStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.refunded:
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  String _formatTransactionType(TransactionType type) {
    switch (type) {
      case TransactionType.product:
        return 'Product';
      case TransactionType.service:
        return 'Service';
      case TransactionType.charging:
        return 'Station Booking';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.reward:
        return 'Reward';
      default:
        return 'Unknown';
    }
  }

  Widget _buildTransactionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(Transaction transaction) {
    // Determine the title and message based on transaction type
    String title;
    String message;

    switch (transaction.type) {
      case TransactionType.product:
        title = 'Cancel Product Order';
        message = 'Are you sure you want to cancel this product order? This action cannot be undone.';
        break;
      case TransactionType.service:
        title = 'Cancel Service Booking';
        message = 'Are you sure you want to cancel this service booking? This action cannot be undone.';
        break;
      case TransactionType.charging:
        title = 'Cancel Station Booking';
        message = 'Are you sure you want to cancel this charging station booking? This action cannot be undone.';
        break;
      default:
        title = 'Cancel Order';
        message = 'Are you sure you want to cancel this order? This action cannot be undone.';
    }

    // Show cancellation confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            // Show order details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Amount: ${transaction.formattedAmount}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Date: ${transaction.formattedDate}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Show refund policy
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A refund will be processed to your original payment method within 3-5 business days.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('NO, KEEP IT'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Process cancellation and show confirmation
              _processCancellation(transaction);
            },
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('YES, CANCEL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _processCancellation(Transaction transaction) {
    // In a real app, this would call an API to cancel the order
    // For now, we'll just show a success message

    // Get the transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    // Determine refund title and message based on transaction type
    String refundTitle;
    String refundDescription;
    String successMessage;

    switch (transaction.type) {
      case TransactionType.product:
        refundTitle = 'Refund - Product Order';
        refundDescription = 'Refund for cancelled product order: ${transaction.id}';
        successMessage = 'Product order cancelled successfully. Refund has been processed.';
        break;
      case TransactionType.service:
        refundTitle = 'Refund - Service Booking';
        refundDescription = 'Refund for cancelled service booking: ${transaction.id}';
        successMessage = 'Service booking cancelled successfully. Refund has been processed.';
        break;
      case TransactionType.charging:
        refundTitle = 'Refund - Station Booking';
        refundDescription = 'Refund for cancelled charging station booking: ${transaction.id}';
        successMessage = 'Station booking cancelled successfully. Refund has been processed.';
        break;
      default:
        refundTitle = 'Refund - ${transaction.title}';
        refundDescription = 'Refund for cancelled order: ${transaction.id}';
        successMessage = 'Order cancelled successfully. Refund has been processed.';
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Add a refund transaction
    transactionProvider.addRefundTransaction(
      title: refundTitle,
      description: refundDescription,
      amount: transaction.amount,
      originalTransactionId: transaction.id,
      paymentMethod: transaction.paymentMethod,
      productName: transaction.productName,
      serviceName: transaction.serviceName,
      stationName: transaction.stationName,
    ).then((_) {
      // Close loading dialog
      Navigator.pop(context);

      // Show cancellation confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancellation Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                successMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Refund Amount:'),
                        Text(
                          transaction.formattedAmount,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method:'),
                        Text(
                          _formatPaymentMethod(transaction.paymentMethod),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Refund Date:'),
                        Text(
                          _getEstimatedRefundDate(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the UI
      setState(() {
        _selectedOrderStatus = 'All';
      });
    }).catchError((error) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  String _getEstimatedRefundDate() {
    // Calculate estimated refund date (3-5 business days from now)
    final now = DateTime.now();
    final refundDate = now.add(const Duration(days: 5));

    // Format the date
    return '${refundDate.day}/${refundDate.month}/${refundDate.year}';
  }

  // Check if a transaction can be cancelled
  bool _canCancelTransaction(Transaction transaction) {
    // Only pending transactions can be cancelled
    if (transaction.status != TransactionStatus.pending) {
      return false;
    }

    // For products and services, always allow cancellation if pending
    if (transaction.type == TransactionType.product ||
        transaction.type == TransactionType.service) {
      return true;
    }

    // For charging stations, check if the booking time has passed
    if (transaction.type == TransactionType.charging) {
      // Get the current time
      final now = DateTime.now();

      // Extract booking date and time from description or use timestamp
      // This is a simplified approach - in a real app, you would store the booking time in the transaction
      DateTime bookingTime;

      // Try to parse booking time from description
      // Example format: "Reserved charging slot at Riverside EV Station for 2023-05-15 14:30"
      final regex = RegExp(r'for (\d{4}-\d{2}-\d{2} \d{2}:\d{2})');
      final match = regex.firstMatch(transaction.description);

      if (match != null && match.groupCount >= 1) {
        try {
          bookingTime = DateTime.parse(match.group(1)!);
        } catch (e) {
          // If parsing fails, use transaction timestamp + 1 day as fallback
          bookingTime = transaction.timestamp.add(const Duration(days: 1));
        }
      } else {
        // If no booking time found in description, use transaction timestamp + 1 day as fallback
        bookingTime = transaction.timestamp.add(const Duration(days: 1));
      }

      // Allow cancellation if current time is before booking time
      return now.isBefore(bookingTime);
    }

    // For other transaction types, don't allow cancellation
    return false;
  }

  Widget _buildTransactionTypeCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
