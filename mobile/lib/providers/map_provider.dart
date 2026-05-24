import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/address_model.dart';

class MapProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  LatLng? _currentLocation;
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  LatLng? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;

  void setAddresses(List<AddressModel> addresses) {
    _addresses = addresses;
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

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

