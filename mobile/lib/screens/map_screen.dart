import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../utils/theme.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load nearby addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapProvider>(context, listen: false).loadNearbyAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Interactive Map
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Центр Бишкека (примерно)
                  center: mapProvider.currentLocation ?? const LatLng(42.8746, 74.5698),
                  zoom: 16.0, // Средний зум - видно дом и окружение
                  minZoom: 14.0,
                  maxZoom: 19.0,
                  interactiveFlags: InteractiveFlag.all, // Разрешить перемещение и зум
                  onTap: (_, __) => mapProvider.deselectAddress(),
                ),
                children: [
                  // OpenStreetMap tiles (бесплатно)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bishkekcourier.app',
                    tileProvider: NetworkTileProvider(),
                  ),

                  // Markers для адресов
                  MarkerLayer(
                    markers: [
                      // Курьер (текущая позиция)
                      if (mapProvider.currentLocation != null)
                        Marker(
                          point: mapProvider.currentLocation!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),

                      // Маркеры адресов
                      ...mapProvider.addresses.map((address) {
                        final isSelected = mapProvider.selectedAddress?.id == address.id;
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
                                      color: isSelected ? AppTheme.accentYellow : AppTheme.errorRed,
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
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        address.name,
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    const Icon(Icons.location_on, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ближайшие адреса',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          Consumer<MapProvider>(
                            builder: (context, mapProvider, _) {
                              return Text(
                                '${mapProvider.addresses.length} доступно',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _mapController.move(
                          Provider.of<MapProvider>(context, listen: false).currentLocation ??
                              const LatLng(42.8746, 74.5698),
                          16.0,
                        );
                      },
                      icon: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: 100,
            child: SafeArea(
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onPressed: () {
                      _mapController.move(_mapController.center, _mapController.zoom + 1);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onPressed: () {
                      _mapController.move(_mapController.center, _mapController.zoom - 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation

    );
  }

  void _showAddressBottomSheet(dynamic address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(address.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(address.address, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,

              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

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
