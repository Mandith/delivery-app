import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/services/auth_service.dart';
import 'package:transport_app/services/firestore_service.dart';
import 'package:transport_app/map_utils.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  late final FirestoreService _firestoreService;
  late final AuthService _authService;

  String? _driverId;
  Stream<QuerySnapshot>? _tripStream;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);

    final user = _authService.getCurrentUser();
    if (user != null) {
      _driverId = user.uid;
      _tripStream = _firestoreService.getActiveTripStream(_driverId!);
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 PICKUP CARD
  // ---------------------------------------------------------------------------

  Widget _pickupCard(Map<String, dynamic> trip, String tripId) {
    final pickupAddress = trip["pickup_address"] ?? "";
    final pickupLat = trip["pickup_lat"];
    final pickupLng = trip["pickup_lng"];

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PICKUP",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Text(pickupAddress,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // --- SHOW ROUTE ---
            ElevatedButton(
              onPressed: () {
                if (pickupLat != null && pickupLng != null) {
                  MapUtils.openGoogleMaps(
                      pickupLat.toDouble(), pickupLng.toDouble());
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Show Route to Pickup"),
            ),

            const SizedBox(height: 10),

            // --- CONFIRM PICKUP ---
            ElevatedButton(
              onPressed: () {
                _firestoreService.updateTripStatus(
                    tripId, _driverId!, "en_route_dropoff");
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm Pickup"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 DROPOFF CARD
  // ---------------------------------------------------------------------------

  Widget _dropoffCard(Map<String, dynamic> trip, String tripId) {
    final List<dynamic> drops = trip["drop_off_points"] ?? [];
    final currentIndex = trip["current_drop_index"] ?? 0;

    Map<String, dynamic> currentDrop = drops[currentIndex];

    final dropAddress = currentDrop["address"];
    final dropLat = currentDrop["lat"];
    final dropLng = currentDrop["lng"];

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("DROP-OFF (${currentIndex + 1} of ${drops.length})",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Text(dropAddress,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // --- SHOW ROUTE TO DROP ---
            ElevatedButton(
              onPressed: () {
                if (dropLat != null && dropLng != null) {
                  MapUtils.openGoogleMaps(
                      dropLat.toDouble(), dropLng.toDouble());
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Show Route to ${dropAddress}"),
            ),

            const SizedBox(height: 10),

            // --- CONFIRM DROP ---
            ElevatedButton(
              onPressed: () {
                _firestoreService.confirmDropOff(
                  tripId,
                  _driverId!,
                  currentIndex,
                  drops.length,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm Drop-off"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 UI BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Active Job"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.signOut();
              Navigator.pushReplacementNamed(context, "/login");
            },
          )
        ],
      ),
      body: _driverId == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: _tripStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No active trips assigned."));
                }

                final doc = snapshot.data!.docs.first;
                final trip = doc.data() as Map<String, dynamic>;
                final tripId = doc.id;
                final status = trip["status"];

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow("Vehicle", trip["vehicle"]),
                              _infoRow(
                                  "Commission", "Rs ${trip["commission"]}"),
                            ],
                          ),
                        ),
                      ),
                      if (status == "en_route_pickup")
                        _pickupCard(trip, tripId),
                      if (status == "en_route_dropoff")
                        _dropoffCard(trip, tripId),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
