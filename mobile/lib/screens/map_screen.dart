import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/map_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';
import '../utils/theme.dart';
import 'address_detail_screen.dart';
import 'profile_screen.dart';
import 'contribute_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  int _selectedIndex = 0;
  bool _isLoadingLocation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Request location permission
    await _requestLocationPermission();

    // Get current location
    await _getCurrentLocation();

    // Load nearby addresses
    await _loadNearbyAddresses();
  }

  void _showContributeAddressPicker() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    // Если адрес уже выбран - идем прямо на форму вклада
    if (mapProvider.selectedAddress != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContributeScreen(
            address: mapProvider.selectedAddress!,
          ),
        ),
      ).then((_) => setState(() => _selectedIndex = 0));
      return;
    }

    // Если адрес не выбран - показываем список
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите адрес',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выберите адрес на карте или из списка',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (mapProvider.addresses.isEmpty)
                const Center(
                  child: Text(
                    'Нет доступных адресов рядом',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: mapProvider.addresses.length,
                    itemBuilder: (context, index) {
                      final address = mapProvider.addresses[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryBlue,
                        ),
                        title: Text(
                          address.name,
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          address.address,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContributeScreen(address: address),
                            ),
                          ).then((_) => setState(() => _selectedIndex = 0));
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isDenied) {
      setState(() {
        _errorMessage = 'Разрешите доступ к геолокации для поиска адресов рядом';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Use default Bishkek center
        final mapProvider = Provider.of<MapProvider>(context, listen: false);
        mapProvider.setCurrentLocation(42.8746, 74.5698);
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setCurrentLocation(position.latitude, position.longitude);

      // Move map to current location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16.0,
      );

    } catch (e) {
      debugPrint('Location error: $e');
      // Fallback to Bishkek center
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setCurrentLocation(42.8746, 74.5698);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadNearbyAddresses() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    try {
      final location = mapProvider.currentLocation;
      final response = await _apiService.getNearbyAddresses(
        lat: location?.latitude ?? 42.8746,
        lng: location?.longitude ?? 74.5698,
        radius: 2000,
      );

      if (response['status'] == 'success') {
        final addresses = (response['data'] as List)
            .map((json) => AddressModel.fromJson(json))
            .toList();

        mapProvider.setAddresses(addresses);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Ошибка загрузки адресов';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check screen size for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Stack(
        children: [
          // Interactive Map
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: mapProvider.currentLocation ??
                      const LatLng(42.8746, 74.5698),
                  zoom: 16.0,
                  minZoom: 14.0,
                  maxZoom: 19.0,
                  interactiveFlags: InteractiveFlag.all,
                  onTap: (_, __) => mapProvider.deselectAddress(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bishkekcourier.app',
                    tileProvider: NetworkTileProvider(),
                  ),

                  MarkerLayer(
                    markers: [
                      // Current location marker
                      if (mapProvider.currentLocation != null)
                        Marker(
                          point: mapProvider.currentLocation!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                      // Address markers
                      ...mapProvider.addresses.map((address) {
                        final isSelected =
                            mapProvider.selectedAddress?.id == address.id;
                        return Marker(
                          point: LatLng(address.latitude, address.longitude),
                          width: isSelected ? 60 : 50,
                          height: isSelected ? 60 : 50,
                          child: GestureDetector(
                            onTap: () {
                              mapProvider.selectAddress(address);
                              _showAddressBottomSheet(address);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.accentYellow
                                          : AppTheme.errorRed,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.home,
                                      color: Colors.white,
                                      size: isSelected ? 28 : 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              );
            },
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<MapProvider>(
                        builder: (context, mapProvider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ближайшие адреса',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '${mapProvider.addresses.length} доступно',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      )
                          : const Icon(
                        Icons.my_location,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),
            ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: isSmallScreen ? 80 : 100,
            child: SafeArea(
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onPressed: () {
                      _mapController.move(
                        _mapController.center,
                        _mapController.zoom + 1,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onPressed: () {
                      _mapController.move(
                        _mapController.center,
                        _mapController.zoom - 1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            // Вклад - показываем список адресов для вклада
            _showContributeAddressPicker();
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          }
        },
        backgroundColor: AppTheme.cardDark,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Вклад',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  void _showAddressBottomSheet(AddressModel address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  address.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressDetailScreen(address: address),
                        ),
                      );
                    },
                    child: const Text('Показать информацию о входе'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.primaryBlue),
      ),
    );
  }
}
