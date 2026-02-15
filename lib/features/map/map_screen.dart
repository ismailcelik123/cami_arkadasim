import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/services/signalr_service.dart';

// --- MODELLER ---
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
      name: json['name'] ?? "İsimsiz Cami",
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
    );
  }
}

// ----------------
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng ankaraCenter = LatLng(39.9334, 32.8597);
  final SignalRService _signalRService = SignalRService();
// Diğer kullanıcıların konumlarını tutan Map (UserId -> LatLng)
final Map<String, LatLng> _friendLocations = {};
int? _activeMosqueId; // Şu an hedeflediğimiz cami ID'si
bool _isJourneyActive = false; // Yolculuk başladı mı?

  late MapController mapController;
  Position? currentPosition;
  bool isLoadingLocation = false;

  final double _minMapZoom = 3.0;
  final double _maxMapZoom = 18.0;

  List<Mosque> _mosques = [];
  String _targetVakit = "Yükleniyor...";
  bool _isLoadingApi = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  // Zoom İşlemleri
  void _zoomIn() {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom < _maxMapZoom) {
      mapController.move(mapController.camera.center, currentZoom + 1);
    }
  }

  void _zoomOut() {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom > _minMapZoom) {
      mapController.move(mapController.camera.center, currentZoom - 1);
    }
  }

  // API'den camileri çekme
  Future<void> _fetchMosques(double lat, double lon) async {
    setState(() => _isLoadingApi = true);
    // Emülatör: 10.0.2.2, Gerçek Cihaz: PC IP Adresi
    const String baseUrl = "http://10.0.2.2:5150";

    try {
      final url = Uri.parse("$baseUrl/api/mosques/nearest?lat=$lat&lon=$lon&count=10");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = MosqueResponse.fromJson(data);

        if (mounted) {
          setState(() {
            _mosques = result.mosques;
            _targetVakit = result.targetVakit;
            _isLoadingApi = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingApi = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _targetVakit = "Bağlantı Hatası";
          _isLoadingApi = false;
        });
        // Hata mesajını her seferinde göstermemek için commentledim
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLoadingLocation = false);
        _fetchMosques(ankaraCenter.latitude, ankaraCenter.longitude);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => isLoadingLocation = false);
          _fetchMosques(ankaraCenter.latitude, ankaraCenter.longitude);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        _fetchMosques(ankaraCenter.latitude, ankaraCenter.longitude);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          currentPosition = position;
          isLoadingLocation = false;
        });

        mapController.move(LatLng(position.latitude, position.longitude), 15.0);
        
        // Eğer yolculuk aktifse, konumu sunucuya gönder
        if (_isJourneyActive && _activeMosqueId != null) {
          await _signalRService.sendLocation(
            _activeMosqueId!,
            position.latitude,
            position.longitude,
          );
        }
        
        _fetchMosques(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingLocation = false);
        _fetchMosques(ankaraCenter.latitude, ankaraCenter.longitude);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cami Arkadaşım', style: TextStyle(fontSize: 18)),
            Text(
              'Hedef: $_targetVakit',
              style: TextStyle(fontSize: 12, color: Colors.teal[100]),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: (isLoadingLocation || _isLoadingApi)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _getCurrentLocation,
                    ),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: ankaraCenter,
          initialZoom: 15.0,
          minZoom: _minMapZoom,
          maxZoom: _maxMapZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.camiarkadasim.app',
          ),
          MarkerLayer(
            markers: [
              // 1. KULLANICI KONUMU
              if (currentPosition != null)
                Marker(
                  point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withAlpha(128),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(128),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. CAMİLER
              ..._mosques.map((cami) => Marker(
                    point: LatLng(cami.lat, cami.lon),
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _showCamiDetails(cami),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.teal,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withAlpha(128),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.mosque,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  )),

              // 3. ARKADAŞLAR (Friend Locations)
              ..._friendLocations.entries.map((entry) {
                final friendId = entry.key;
                final friendLocation = entry.value;
                
                return Marker(
                  point: friendLocation,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withAlpha(128),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      // --- ZOOM VE KONUM BUTONLARI ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zoom In Butonu
          FloatingActionButton.small(
            heroTag: "zoom_in", // Hero tag zorunlu!
            onPressed: _zoomIn,
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          // Zoom Out Butonu
          FloatingActionButton.small(
            heroTag: "zoom_out", // Hero tag zorunlu!
            onPressed: _zoomOut,
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 10),
          // Konuma Git Butonu
          FloatingActionButton(
            heroTag: "my_location", // Hero tag zorunlu!
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            tooltip: 'Mevcut Konuma Git',
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _showCamiDetails(Mosque cami) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sürükleme Çubuğu
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.teal[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cami Bilgileri (İkon, İsim, Mesafe)
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal[100],
                  ),
                  child: Icon(
                    FontAwesomeIcons.mosque,
                    color: Colors.teal[800],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cami.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Mesafe: ${cami.distance.toStringAsFixed(0)} metre",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- BUTONLAR ---
            Row(
              children: [
                // 1. BUTON: YOLA ÇIK (Senin SignalR Kodlarını Buraya Koydum)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.teal),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // Pencereyi kapat

                      // --- MEVCUT SIGNALR MANTIĞINIZ (KORUNDU) ---
                      _signalRService.onLocationReceived = (friendId, lat, lon) {
                        setState(() {
                          _friendLocations[friendId] = LatLng(lat, lon);
                        });
                      };

                      _signalRService.onUserLeft = (friendId) {
                        setState(() {
                          _friendLocations.remove(friendId);
                        });
                      };

                      // Emülatör/Cihaz ayrımı için BaseUrl (Düzeltme gerekebilir)
                      // initSignalR metodunuza parametre alacak şekilde ayarladıysanız buraya URL girin.
                      // Eğer parametresiz ise boş bırakın.
                      await _signalRService.initSignalR(); 

                      await _signalRService.joinJourney(cami.id);

                      setState(() {
                        _isJourneyActive = true;
                        _activeMosqueId = cami.id;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${cami.name} için $_targetVakit rotası ve canlı takip başladı...'),
                        ),
                      );
                      // -------------------------------------------
                    },
                    icon: const Icon(Icons.directions_walk, color: Colors.teal),
                    label: const Text('Namaza Git', style: TextStyle(color: Colors.teal)),
                  ),
                ),

                const SizedBox(width: 10),

                // 2. BUTON: CHECK-IN YAP (Yeni Eklenen Puan Özelliği)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber, // Dikkat çekici renk
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Pencereyi kapat
                      _performCheckIn(cami);  // Backend'e sor ve puanı al
                    },
                    icon: const Icon(Icons.verified),
                    label: const Text('Check-In'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


  // Check-In İşlemi
Future<void> _performCheckIn(Mosque mosque) async {
  // 1. Konumdan emin ol
  if (currentPosition == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Konumunuz alınamadı, lütfen bekleyin.")),
    );
    return;
  }

  // Yükleniyor göstergesi
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  // 2. API İsteği Hazırla
  // Emülatör: 10.0.2.2, Gerçek Cihaz: PC IP'si
  const String baseUrl = "http://10.0.2.2:5150"; 
  final url = Uri.parse("$baseUrl/api/mosques/checkin");

  try {
    final body = json.encode({
      "mosqueId": mosque.id,
      "lat": currentPosition!.latitude,
      "lon": currentPosition!.longitude,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    // Dialog'u kapat
    if (mounted) Navigator.pop(context);

    if (response.statusCode == 200) {
      // --- BAŞARILI ---
      final data = json.decode(response.body);
      final message = data['message'] ?? "İşlem Başarılı";
      final points = data['pointsEarned'] ?? 0;

      _showSuccessDialog(message, points);
    } else {
      // --- HATA (Mesafe veya Süre) ---
      // Backend'den gelen hata mesajını oku (örn: "50m yaklaşmalısınız")
      String errorMessage = "Bir hata oluştu.";
      try {
         // Backend düz string dönerse diye kontrol:
         errorMessage = response.body; 
         // Veya JSON dönüyorsa: json.decode(response.body)['message'];
      } catch (_) {}

      _showErrorDialog(errorMessage);
    }
  } catch (e) {
    if (mounted) Navigator.pop(context); // Dialog kapat
    _showErrorDialog("Bağlantı hatası: $e");
  }
}

// Başarılı olursa çıkacak havalı pencere
void _showSuccessDialog(String message, int points) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.stars, color: Colors.amber, size: 30),
          SizedBox(width: 10),
          Text("Tebrikler!"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 20),
          Text(
            "+$points Puan",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Harika!"),
        )
      ],
    ),
  );
}

// Hata olursa çıkacak pencere
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Check-In Başarısız"),
      content: Text(message), // Backend'den gelen "Uzaklığı kontrol et" mesajı burada yazar
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Tamam"),
        )
      ],
    ),
  );
}


}