import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

class LocationResult {
  final String address;
  final double lat;
  final double lng;

  LocationResult({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String title; // "Select Pickup Location" or "Select Drop Location"

  const LocationPickerScreen({super.key, required this.title});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GooglePlace _googlePlace;
  final TextEditingController _searchController = TextEditingController();

  List<AutocompletePrediction> _predictions = [];
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    // Your real API key
    const apiKey = "AIzaSyDnAbK5w9WYstKQ0M9-l9_m2h2uIwbCBxY";

    _googlePlace = GooglePlace(apiKey);
  }

  // --- SEARCH BAR LISTENER ---
  void _searchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    final result = await _googlePlace.autocomplete.get(value);

    setState(() {
      _predictions = result?.predictions ?? [];
    });
  }

  // --- WHEN A PLACE IS SELECTED FROM SEARCH RESULTS ---
  Future<void> _selectPrediction(AutocompletePrediction prediction) async {
    final placeId = prediction.placeId;
    if (placeId == null) return;

    final details = await _googlePlace.details.get(placeId);
    final geometry = details?.result?.geometry?.location;

    if (geometry == null) return;

    final lat = geometry.lat!;
    final lng = geometry.lng!;
    final address =
        details?.result?.formattedAddress ?? prediction.description ?? "";

    setState(() {
      _selectedLatLng = LatLng(lat, lng);
      _selectedAddress = address;
      _searchController.text = address;
      _predictions = [];
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLatLng!, 16),
    );
  }

  // --- CONFIRM LOCATION AND RETURN TO MANAGER SCREEN ---
  void _confirm() {
    if (_selectedAddress == null || _selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      LocationResult(
        address: _selectedAddress!,
        lat: _selectedLatLng!.latitude,
        lng: _selectedLatLng!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const sriLankaCenter = LatLng(7.8731, 80.7718);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text(
              "DONE",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search location...",
                border: OutlineInputBorder(),
              ),
              onChanged: _searchChanged,
            ),
          ),

          // --- AUTOCOMPLETE RESULTS ---
          if (_predictions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(p.description ?? ""),
                    onTap: () => _selectPrediction(p),
                  );
                },
              ),
            )
          else
            // --- GOOGLE MAP ---
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: sriLankaCenter,
                  zoom: 7,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _selectedLatLng == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId("selected"),
                          position: _selectedLatLng!,
                        ),
                      },
                onTap: (latLng) {
                  setState(() {
                    _selectedLatLng = latLng;
                    _selectedAddress =
                        "Lat: ${latLng.latitude}, Lng: ${latLng.longitude}";
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
