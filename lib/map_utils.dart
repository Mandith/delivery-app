import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static Future<void> openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch Google Maps";
    }
  }

  static Future<void> openGoogleMapsText(String address) async {
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch Google Maps";
    }
  }
}
