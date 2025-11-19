import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/services/auth_service.dart';
import 'package:transport_app/services/firestore_service.dart';
import 'package:transport_app/screens/location_picker.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  late final FirestoreService _firestoreService;
  late final AuthService _authService;

  Stream<QuerySnapshot>? _driversStream;
  String _managerId = '';

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _driversStream = _firestoreService.getDriversStream();

    _managerId = _authService.getCurrentUser()?.uid ?? '';
  }

  // ---------------------------------------------------------------------------
  // 🚀 ADD DRIVER POPUP
  // ---------------------------------------------------------------------------

  void _showAddDriverDialog() {
    final email = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    final vehicle = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Driver"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(name, "Name"),
                _field(email, "Email"),
                _field(password, "Password", isPassword: true),
                _field(vehicle, "Vehicle"),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final result = await _firestoreService.addDriver(
                    email: email.text.trim(),
                    password: password.text.trim(),
                    name: name.text.trim(),
                    vehicle: vehicle.text.trim(),
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(result), backgroundColor: Colors.green),
                  );
                },
                child: const Text("Add"))
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 ASSIGN TRIP POPUP WITH MAP PICKER
  // ---------------------------------------------------------------------------

  void _showAssignTripDialog(String driverId, String driverName) {
    final vehicle = TextEditingController();
    final commission = TextEditingController();
    LocationResult? pickupLocation;
    final List<LocationResult> dropLocations = [];

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Assign Trip → $driverName"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PICKUP PICKER BUTTON
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationPickerScreen(
                                    title: "Select Pickup Location",
                                  ),
                                ),
                              );

                              if (result != null) {
                                setStateDialog(() {
                                  pickupLocation = result;
                                });
                              }
                            },
                            child: const Text("Pick Pickup Location"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      if (pickupLocation != null)
                        Text(
                          "Pickup: ${pickupLocation!.address}",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.green),
                        ),

                      const SizedBox(height: 20),

                      _field(vehicle, "Vehicle"),
                      _field(commission, "Commission", isNumber: true),

                      const SizedBox(height: 20),

                      // DROP LOCATIONS BUTTON
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocationPickerScreen(
                                  title: "Select Drop Location"),
                            ),
                          );

                          if (result != null) {
                            setStateDialog(() {
                              dropLocations.add(result);
                            });
                          }
                        },
                        child: const Text("Add Drop-off Location"),
                      ),

                      const SizedBox(height: 10),

                      // LIST OF DROPS
                      ...dropLocations.map((e) => Text("• ${e.address}")),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (pickupLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select pickup"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (dropLocations.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Add at least 1 drop point"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final drops = dropLocations
                        .map(
                          (e) => {
                            "address": e.address,
                            "lat": e.lat,
                            "lng": e.lng,
                          },
                        )
                        .toList();

                    await _firestoreService.assignTrip(
                      driverId: driverId,
                      assignedBy: _managerId,
                      pickupAddress: pickupLocation!.address,
                      pickupLat: pickupLocation!.lat,
                      pickupLng: pickupLocation!.lng,
                      vehicle: vehicle.text.trim(),
                      commission: double.tryParse(commission.text) ?? 0.0,
                      dropOffPoints: drops,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Trip Assigned Successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text("Assign"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 DELETE DRIVER
  // ---------------------------------------------------------------------------

  void _showDeleteDriverDialog(String driverId, String driverName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Driver $driverName?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.deleteDriver(driverId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _driversStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final d = drivers[index];
              final data = d.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: data['driver_status'] == 'free'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Text("Vehicle: ${data['vehicle']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteDriverDialog(d.id, data['name']),
                      ),
                      if (data['driver_status'] == 'free')
                        ElevatedButton(
                          onPressed: () =>
                              _showAssignTripDialog(d.id, data['name']),
                          child: const Text("Assign"),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 REUSABLE TEXT FIELD
  // ---------------------------------------------------------------------------

  Widget _field(TextEditingController c, String label,
      {bool isPassword = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        obscureText: isPassword,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }
}
