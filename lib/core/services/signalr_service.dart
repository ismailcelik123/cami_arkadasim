import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  late HubConnection hubConnection;
  
  // Olayları dinlemek için callback fonksiyonları
  Function(String userId, double lat, double lon)? onLocationReceived;
  Function(String userId)? onUserLeft;

  // Android Emulator için Base URL
  static const String _baseUrl = "http://10.0.2.2:5150";

  // Bağlantıyı Başlat
  Future<void> initSignalR() async {
    // Emulator için: http://10.0.2.2:5150/journeyHub
    final serverUrl = "$_baseUrl/journeyHub";

    hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

    // Backend'den gelen "ReceiveLocation" mesajını dinle
    hubConnection.on("ReceiveLocation", (arguments) {
      if (arguments != null && arguments.length >= 3) {
        final userId = arguments[0] as String;
        final lat = arguments[1] as double;
        final lon = arguments[2] as double;
        
        // UI'a haber ver
        onLocationReceived?.call(userId, lat, lon);
      }
    });

    // Backend'den gelen "UserLeft" mesajını dinle
    hubConnection.on("UserLeft", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final userId = arguments[0] as String;
        onUserLeft?.call(userId);
      }
    });

    await hubConnection.start();
    print("SignalR Bağlandı! ID: ${hubConnection.connectionId}");
  }

  // Odaya Katıl (Namaza Git Butonuna basınca)
  Future<void> joinJourney(int mosqueId) async {
    try {
      await hubConnection.invoke("JoinJourney", args: [mosqueId]);
      print("Odaya (Cami $mosqueId) girildi.");
    } catch (e) {
      print("JoinJourney hatası: $e");
    }
  }

  // Konum Gönder (Her konum değişiminde)
  Future<void> sendLocation(int mosqueId, double lat, double lon) async {
    try {
      await hubConnection.invoke("SendLocation", args: [mosqueId, lat, lon]);
    } catch (e) {
      print("SendLocation hatası: $e");
    }
  }

  // Odadan Ayrıl
  Future<void> leaveJourney(int mosqueId) async {
    try {
      await hubConnection.invoke("LeaveJourney", args: [mosqueId]);
    } catch (e) {
      print("LeaveJourney hatası: $e");
    }
  }
}