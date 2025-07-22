import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location.dart';
import '../services/api_service.dart';
import '../models/transaction.dart';
import 'package:flutter_application_1/models/station.dart';
import 'package:flutter_application_1/models/vehicle.dart';
import 'package:flutter_application_1/screens/booking_confirmation_screen.dart';
import 'package:flutter_application_1/screens/payment_screen.dart';
import 'package:flutter_application_1/screens/payment_confirmation_screen.dart';
import '../providers/admin_provider.dart';
import 'package:provider/provider.dart';
import '../models/charging_station.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = false;
  MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(12.9716, 77.5946); // Default to Bangalore
  ChargingStation? _selectedStation;
  double _estimatedCost = 0.0; // Add estimated cost variable

  // Mock vehicle for the booking screen
  final Vehicle _mockVehicle = Vehicle(
    id: '1',
    make: 'Tesla',
    model: 'Model 3',
    licensePlate: 'EV-123',
    batteryCapacity: '75',
    currentCharge: 30,
    chargerType: 'Type 2',
    year: 2023,
    imageUrl: 'assets/images/tesla_model_3.png',
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final stations = adminProvider.stations;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green,
            title: const Text('Charging Stations Map'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Show filter options
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Show search
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Reload stations
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Map view
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _defaultLocation,
                    zoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: stations.map(
                        (station) => Marker(
                          point: LatLng(station.latitude, station.longitude),
                          width: 80,
                          height: 80,
                          builder: (context) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStation = station;
                              });
                              _showStationDetails(station);
                            },
                            child: Icon(
                              Icons.ev_station,
                              color: _getStatusColor(station.status),
                              size: 40,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
              // Station list
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nearby Charging Stations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: stations.isEmpty
                            ? const Center(child: Text('No stations available'))
                            : ListView.builder(
                                itemCount: stations.length,
                                itemBuilder: (context, index) {
                                  final station = stations[index];
                                  final isSelected = _selectedStation?.id == station.id;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: isSelected ? 4 : 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isSelected
                                          ? const BorderSide(color: Colors.green, width: 2)
                                          : BorderSide.none,
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.ev_station,
                                        color: _getStatusColor(station.status),
                                      ),
                                      title: Text(station.name),
                                      subtitle: Text(station.address),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(station.status),
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
                                      onTap: () {
                                        setState(() {
                                          _selectedStation = station;
                                        });
                                        _mapController.move(
                                          LatLng(station.latitude, station.longitude),
                                          15.0,
                                        );
                                        _showStationDetails(station);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStationDetails(ChargingStation station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(station.status),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStationInfoItem(
                  icon: Icons.bolt,
                  label: '${station.powerKw} kW',
                  color: Colors.orange,
                ),
                _buildStationInfoItem(
                  icon: Icons.attach_money,
                  label: '\$${station.pricePerKwh.toStringAsFixed(2)}/kWh',
                  color: Colors.green,
                ),
                _buildStationInfoItem(
                  icon: Icons.access_time,
                  label: '24/7',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Connector Types',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: station.connectorTypes.map((type) {
                return Chip(
                  label: Text(type.toString().split('.').last),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.green),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: station.status == StationStatus.available
                    ? () {
                        Navigator.pop(context);
                        _showTimeSlotPicker(station);
                    }
                    : null,
                icon: const Icon(Icons.bolt),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: station.status == StationStatus.available
                      ? Colors.green
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotPicker(ChargingStation station) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedDuration = 30; // Default 30 minutes

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Declare as local variable so it persists and updates
        double costForDuration = (station.pricePerKwh * station.powerKw * selectedDuration) / 60;

        return StatefulBuilder(
          builder: (context, setState) {
            void updateDuration(int newDuration) {
              setState(() {
                selectedDuration = newDuration;
                costForDuration = (station.pricePerKwh * station.powerKw * selectedDuration) / 60;
              });
            }

            return AlertDialog(
              title: const Text('Select Time Slot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
                      items: [30, 60, 90, 120].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value min'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          updateDuration(newValue);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Estimated Cost'),
                    trailing: Text(
                      '\$${costForDuration.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          initialAmount: costForDuration,
                          description: 'Charging session at ${station.name}',
                          stationId: station.id,
                          stationName: station.name,
                          transactionType: TransactionType.charging,
                          onPaymentSuccess: (double amount, String transactionId, String paymentMethod) {
                            // Show payment confirmation screen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => PaymentConfirmationScreen(
                                  amount: amount,
                                  transactionId: transactionId,
                                  paymentDate: DateTime.now(),
                                  paymentMethod: paymentMethod,
                                  onContinue: () {
                                    // Navigate to booking confirmation
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => BookingConfirmationScreen(
                                          station: Station(
                                            id: station.id,
                                            name: station.name,
                                            address: station.address,
                                            latitude: station.latitude,
                                            longitude: station.longitude,
                                            imageUrl: '',
                                            availableChargerTypes: station.connectorTypes.map((t) => t.toString()).toList(),
                                            totalChargers: 1,
                                            availableChargers: 1,
                                            rating: 4.5,
                                            reviewCount: 0,
                                            amenities: ['Parking', 'Restroom', 'WiFi'],
                                            operatingHours: '24/7',
                                            available: true,
                                            type: 'EV Charger',
                                            distance: '0.5 km',
                                            price: '${station.pricePerKwh}/kWh',
                                            vehicle: _mockVehicle
                                          ),
                                          selectedDate: selectedDate,
                                          startTime: selectedTime,
                                          durationMinutes: selectedDuration,
                                          vehicle: _mockVehicle,
                                          chargerType: station.connectorTypes.first.toString().split('.').last,
                                          chargerNumber: 1,
                                          paymentMethod: paymentMethod, // Use the actual payment method
                                          transactionId: transactionId, // Add transaction ID
                                          amount: amount, // Pass the actual payment amount
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


  Widget _buildStationInfoItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(StationStatus status) {
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
}
