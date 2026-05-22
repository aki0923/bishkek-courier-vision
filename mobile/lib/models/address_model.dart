class AddressModel {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalEntrances;
  final bool hasSecurity;

  AddressModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalEntrances,
    required this.hasSecurity,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      totalEntrances: json['total_entrances'] ?? 1,
      hasSecurity: json['has_security'] == 1,
    );
  }
}