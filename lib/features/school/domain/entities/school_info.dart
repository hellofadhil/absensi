class SchoolInfo {
  final String name;
  final String npsn;
  final String startTime;
  final String lateTime;
  final double latitude;
  final double longitude;
  final String address;
  final double radius;

  const SchoolInfo({
    required this.name,
    required this.npsn,
    required this.startTime,
    required this.lateTime,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.radius = 50.0,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      name: json['name'] as String? ?? 'SMK TI Bazma',
      npsn: json['npsn'] as String? ?? '699881122',
      startTime: json['startTime'] as String? ?? '07:00',
      lateTime: json['lateTime'] as String? ?? '07:15',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -6.4682054,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.8402422,
      address: json['address'] as String? ?? 'Jl. Raya Ciawi-Sukabumi No.KM. 1, Bojong Koneng, Kec. Babakan Madang, Kabupaten Bogor, Jawa Barat 16810',
      radius: (json['radius'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'npsn': npsn,
      'startTime': startTime,
      'lateTime': lateTime,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'radius': radius,
    };
  }

  SchoolInfo copyWith({
    String? name,
    String? npsn,
    String? startTime,
    String? lateTime,
    double? latitude,
    double? longitude,
    String? address,
    double? radius,
  }) {
    return SchoolInfo(
      name: name ?? this.name,
      npsn: npsn ?? this.npsn,
      startTime: startTime ?? this.startTime,
      lateTime: lateTime ?? this.lateTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      radius: radius ?? this.radius,
    );
  }
}
