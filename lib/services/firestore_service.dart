import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // 🚀 USER & ROLE (FIXED + LOGS)
  // ---------------------------------------------------------------------------

  Future<String?> getUserRole(String uid) async {
    print("FETCHING USER ROLE FOR UID = $uid");

    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        print("ROLE ERROR: User document NOT FOUND for UID = $uid");
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'];

      print("🔥 USER ROLE = $role");

      return role;
    } catch (e) {
      print("ROLE FETCH ERROR: $e");
      return null;
    }
  }

  Stream<QuerySnapshot> getDriversStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // 🚀 DRIVER LIVE LOCATION UPDATES
  // ---------------------------------------------------------------------------

  Future<void> updateDriverLocation(
      String driverId, double lat, double lng) async {
    try {
      await _db.collection('users').doc(driverId).update({
        'live_lat': lat,
        'live_lng': lng,
        'last_updated': Timestamp.now(),
      });

      print("📍 Driver $driverId location updated ($lat,$lng)");
    } catch (e) {
      print("Error updating driver location: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 HIGHER MANAGEMENT – ALL DRIVER LOCATIONS
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot> getAllDriverLocations() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // 🚀 TRIPS (ACTIVE DRIVER TRIP)
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot> getActiveTripStream(String driverId) {
    print("Listening for active trips for driver $driverId...");

    return _db
        .collection('trips')
        .where('driver_id', isEqualTo: driverId)
        .where('status', isNotEqualTo: 'completed')
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllTripsStream() {
    return _db.collection('trips').snapshots();
  }

  // ---------------------------------------------------------------------------
  // 🚀 DRIVER ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> updateTripStatus(
      String tripId, String driverId, String status) async {
    try {
      await _db.collection('trips').doc(tripId).update({
        'status': status,
        'updated_at': Timestamp.now(),
      });

      await _db.collection('users').doc(driverId).update({
        'driver_status': status == 'completed' ? 'free' : 'busy',
      });

      print("Trip $tripId updated to status = $status");
    } catch (e) {
      print("Error updating trip status: $e");
    }
  }

  Future<void> confirmDropOff(
      String tripId, String driverId, int index, int total) async {
    try {
      if (index < total - 1) {
        await _db.collection('trips').doc(tripId).update({
          'current_drop_index': index + 1,
          'updated_at': Timestamp.now(),
        });

        print("Next drop index moved to ${index + 1}");
      } else {
        await _db.collection('trips').doc(tripId).update({
          'status': 'completed',
          'completed_at': Timestamp.now(),
        });

        await _db.collection('users').doc(driverId).update({
          'driver_status': 'free',
        });

        print("Trip $tripId completed");
      }
    } catch (e) {
      print("Error confirmDropOff: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 MANAGER ACTIONS
  // ---------------------------------------------------------------------------

  Future<String> addDriver({
    required String email,
    required String password,
    required String name,
    required String vehicle,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'vehicle': vehicle,
        'role': 'driver',
        'driver_status': 'free',
        'live_lat': null,
        'live_lng': null,
        'created_at': Timestamp.now(),
      });

      print("Driver added: $email ($uid)");

      return 'Success';
    } catch (e) {
      print("Error adding driver: $e");
      return 'Error: $e';
    }
  }

  Future<void> deleteDriver(String driverId) async {
    try {
      await _db.collection('users').doc(driverId).delete();
      print("Driver deleted: $driverId");
    } catch (e) {
      print("Error deleting driver: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 ASSIGN TRIP WITH MAP LOCATIONS
  // ---------------------------------------------------------------------------

  Future<void> assignTrip({
    required String driverId,
    required String assignedBy,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String vehicle,
    required double commission,
    required List<Map<String, dynamic>> dropOffPoints,
  }) async {
    try {
      await _db.collection('trips').add({
        'driver_id': driverId,
        'assigned_by': assignedBy,

        // Pickup info
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,

        // Vehicle & Payment
        'vehicle': vehicle,
        'commission': commission,

        // Drop List
        'drop_off_points': dropOffPoints,

        'current_drop_index': 0,
        'status': 'en_route_pickup',
        'assigned_time': Timestamp.now(),
      });

      await _db.collection('users').doc(driverId).update({
        'driver_status': 'busy',
      });

      print("Trip assigned to driver $driverId");
    } catch (e) {
      print("Error assigning trip: $e");
    }
  }
}
