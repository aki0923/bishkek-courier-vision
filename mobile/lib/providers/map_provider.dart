import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';

class MapProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  LatLng? _currentLocation;
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  LatLng? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;

  Future<void> loadNearbyAddresses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.getNearbyAddresses();

      if (response['status'] == 'success') {
        _addresses = (response['data'] as List)
            .map((json) => AddressModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void deselectAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  void setCurrentLocation(double lat, double lng) {
    _currentLocation = LatLng(lat, lng);
    notifyListeners();
  }
}