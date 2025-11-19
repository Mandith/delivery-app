import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:transport_app/services/auth_service.dart';
import 'package:transport_app/services/firestore_service.dart';

class HigherHome extends StatefulWidget {
  const HigherHome({super.key});

  @override
  State<HigherHome> createState() => _HigherHomeState();
}

class _HigherHomeState extends State<HigherHome> {
  late final FirestoreService _firestoreService;
  late final AuthService _authService;

  Stream<QuerySnapshot>? _tripsStream;
  Stream<QuerySnapshot>? _driversStream;

  GoogleMapController? _mapController;

  static const LatLng sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);

    _tripsStream = _firestoreService.getAllTripsStream();
    _driversStream = _firestoreService.getAllDriverLocations();
  }

  // ---------------------------------------------------------------------------
  // 🚀 KPI CARD WIDGET
  // ---------------------------------------------------------------------------

  Widget _buildKPICard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 TRIP COMPLETION CARD
  // ---------------------------------------------------------------------------

  Widget _buildStatusCard(int completed, int total) {
    final double percent = total == 0 ? 0.0 : (completed / total) * 100;
    final color = percent > 80 ? Colors.green : Colors.orange;
    final text = total == 0
        ? "No Trips Yet"
        : "${percent.toStringAsFixed(1)}% Completed";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Trip Completion Rate",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total == 0 ? 0.0 : completed / total,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 DRIVER MAP WIDGET
  // ---------------------------------------------------------------------------

  Widget _buildDriverMap(AsyncSnapshot<QuerySnapshot> driverSnap) {
    if (!driverSnap.hasData || driverSnap.data!.docs.isEmpty) {
      return const Center(
        child: Text("No driver locations yet."),
      );
    }

    final drivers = driverSnap.data!.docs;

    final Set<Marker> markers = {};

    for (var doc in drivers) {
      final data = doc.data() as Map<String, dynamic>;

      final lat = data['live_lat'];
      final lng = data['live_lng'];

      if (lat == null || lng == null) continue;

      final name = data['name'] ?? 'Driver';
      final vehicle = data['vehicle'] ?? 'Vehicle';
      final status = data['driver_status'] ?? 'unknown';

      markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat.toDouble(), lng.toDouble()),
          infoWindow: InfoWindow(
            title: name,
            snippet: "$vehicle • $status",
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 280,
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: sriLankaCenter,
            zoom: 7,
          ),
          markers: markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Higher Management Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              _authService.signOut();
              Navigator.pushReplacementNamed(context, "/login");
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tripsStream,
        builder: (context, tripSnap) {
          if (tripSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tripSnap.hasError) {
            return Center(
                child: Text("Error loading trips: ${tripSnap.error}"));
          }

          final trips = tripSnap.data?.docs ?? [];
          final totalTrips = trips.length;

          int completedTrips = 0;
          int activeTrips = 0;
          double totalCommission = 0;

          for (var doc in trips) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final commission = (data['commission'] ?? 0.0).toDouble();

            if (status == 'completed') {
              completedTrips++;
            } else {
              activeTrips++;
            }

            totalCommission += commission;
          }

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Company Overview",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // KPI WRAP
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildKPICard(
                          "Total Trips", "$totalTrips", Colors.blueGrey),
                      const SizedBox(width: 10),
                      _buildKPICard(
                          "Completed", "$completedTrips", Colors.green),
                      const SizedBox(width: 10),
                      _buildKPICard(
                          "Active/Pending", "$activeTrips", Colors.orange),
                      const SizedBox(width: 10),
                      _buildKPICard(
                          "Total Commission",
                          "Rs ${totalCommission.toStringAsFixed(0)}",
                          Colors.teal),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _buildStatusCard(completedTrips, totalTrips),
                const SizedBox(height: 18),

                const Text("Driver Map (Sri Lanka)",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // DRIVER MAP STREAM
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _driversStream,
                    builder: (context, driverSnap) {
                      if (driverSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (driverSnap.hasError) {
                        return Center(
                            child: Text(
                                "Error loading drivers: ${driverSnap.error}"));
                      }
                      return _buildDriverMap(driverSnap);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
