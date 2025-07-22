import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/location.dart';
import '../../services/api_service.dart';

class LocationManagement extends StatefulWidget {
  const LocationManagement({super.key});

  @override
  State<LocationManagement> createState() => _LocationManagementState();
}

class _LocationManagementState extends State<LocationManagement> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  List<StoreLocation> _locations = [];
  bool _isLoading = false;
  MapController _mapController = MapController();
  LatLng _selectedLocation = LatLng(12.9716, 77.5946); // Default to Bangalore

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final locations = await ApiService().getLocations();
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Error loading locations: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _addressController.clear();
    _countryController.clear();
    _cityController.clear();
    _stateController.clear();
    setState(() {
      _selectedLocation = LatLng(12.9716, 77.5946);
    });
  }

  Future<void> _addLocation() async {
    if (_formKey.currentState!.validate()) {
      try {
        final location = StoreLocation(
          address: _addressController.text,
          country: _countryController.text,
          city: _cityController.text,
          state: _stateController.text,
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        );

        await ApiService().addLocation(location);
        _resetForm();
        await _loadLocations();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location added successfully')),
          );
        }
      } catch (e) {
        _showErrorDialog('Error adding location: \\n${e.toString()}');
      }
    }
  }

  Future<void> _deleteLocation(StoreLocation location) async {
    try {
      await ApiService().deleteLocation(location.id!);
      await _loadLocations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted successfully')),
        );
      }
    } catch (e) {
      _showErrorDialog('Error deleting location: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _selectedLocation,
                  zoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocation = point;
                      _countryController.text = '';
                      _cityController.text = '';
                      _stateController.text = '';
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      ..._locations.map(
                        (location) => Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 80,
                          height: 80,
                          builder: (context) => Icon(
                            Icons.location_on,
                            color: Colors.red[700],
                            size: 40,
                          ),
                        ),
                      ),
                      Marker(
                        point: _selectedLocation,
                        width: 80,
                        height: 80,
                        builder: (context) => const Icon(
                          Icons.add_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add Location Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a street address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a country';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a city';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State/Province',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a state/province';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addLocation,
                    child: const Text('Add Location'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Locations List
            const Text(
              'Existing Locations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_locations.isEmpty)
              const Center(child: Text('No locations added yet'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return Card(
                    child: ListTile(
                      title: Text(location.address),
                      subtitle: Text(
                        '${location.city}, ${location.state}, ${location.country}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteLocation(location),
                      ),
                      onTap: () {
                        _mapController.move(
                          LatLng(location.latitude, location.longitude),
                          15.0,
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}