class MosqueResponse {
  final String targetVakit;
  final List<Mosque> mosques;

  MosqueResponse({required this.targetVakit, required this.mosques});

  factory MosqueResponse.fromJson(Map<String, dynamic> json) {
    var list = json['mosques'] as List;
    List<Mosque> mosqueList = list.map((i) => Mosque.fromJson(i)).toList();

    return MosqueResponse(
      targetVakit: json['targetVakit'] ?? "Bilinmiyor",
      mosques: mosqueList,
    );
  }
}

class Mosque {
  final int id;
  final String name;
  final double lat;
  final double lon;
  final double distance;

  Mosque({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.distance,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      id: json['id'] ?? 0,
      name: json['name'] ?? "İsimsiz",
      lat: json['lat'],
      lon: json['lon'],
      distance: json['distance'],
    );
  }
}