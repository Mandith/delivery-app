import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- FIREBASE IMPORTS ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // The file you just created

// --- SCREEN IMPORTS ---
import 'screens/login.dart';
import 'screens/driver_home.dart';
import 'screens/manager_home.dart';
import 'screens/higher_home.dart';

// --- SERVICE IMPORTS ---
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/fcm_service.dart';

// --- MAIN FUNCTION (NO CHANGE NEEDED) ---
void main() async {
  // This is the most important part
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // We run JayaFreightApp as the main app widget
  runApp(const JayaFreightApp());
}

// 📌 FIX: ADDED MyApp class for widget_test.dart
// widget_test.dart looks for a class named MyApp. This delegates to your main app class.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const JayaFreightApp();
  }
}

class JayaFreightApp extends StatelessWidget {
  const JayaFreightApp({super.key});

  final Color jayaGreen = const Color(0xFF2ecc71); // Your plan's color

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<FCMService>(create: (_) => FCMService()..init()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JAYA FREIGHT',
        theme: ThemeData(
          // Using your plan's theme
          colorScheme: ColorScheme.fromSeed(seedColor: jayaGreen),
          appBarTheme: const AppBarTheme(
            // 📌 FIX: Added const
            backgroundColor:
                Color(0xFF2ecc71), // Use explicit color or jayaGreen
            foregroundColor: Colors.white,
            elevation: 4,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          useMaterial3: true,
        ),
        // Start at the SplashScreen
        home: const SplashScreen(),

        // Named routes for navigating AFTER login
        routes: {
          // 📌 FIX: Added const keyword to all route builders
          '/login': (context) => const LoginScreen(),
          '/driver': (context) => const DriverHome(),
          '/manager': (context) => const ManagerHome(),
          '/higher': (context) => const HigherHome(),
        },
      ),
    );
  }
}

// --- YOUR SPLASH SCREEN (NOW SMARTER) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to ensure provider is available before accessing it
    Future.microtask(() => _checkUserAndNavigate());
  }

  Future<void> _checkUserAndNavigate() async {
    // Wait 2 seconds (for your logo)
    await Future.delayed(const Duration(seconds: 2));

    // Get services
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    // Check if user is already logged in
    final user = authService.getCurrentUser();

    if (user == null) {
      // NO user, go to Login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // YES user, get their role
      final role = await firestoreService.getUserRole(user.uid);

      if (!mounted) return; // Check again after await

      // Navigate based on role
      switch (role) {
        case 'driver':
          Navigator.pushReplacementNamed(context, '/driver');
          break;
        case 'manager':
          Navigator.pushReplacementNamed(context, '/manager');
          break;
        case 'higher':
          Navigator.pushReplacementNamed(context, '/higher');
          break;
        default:
          // Unknown role or error, go to login
          Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2ecc71), // Your green color
      body: Center(
        child: Text(
          'JAYA FREIGHT',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
