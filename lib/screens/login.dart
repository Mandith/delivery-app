import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport_app/services/auth_service.dart';
import 'package:transport_app/services/firestore_service.dart';

// Needs to be a StatefulWidget to hold text controllers and loading state
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Corrected constructor

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to get text from text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _errorMessage = '';

  // The main login function
  Future<void> _login() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Clear old errors
    });

    // Get services from Provider
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    try {
      // 1. Sign in the user
      final user = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null) {
        // Sign in failed (wrong password, etc.)
        setState(() {
          _errorMessage = 'Login failed. Please check your email and password.';
        });
      } else {
        // 2. User is signed in! Now get their role.
        final role = await firestoreService.getUserRole(user.uid);

        if (!mounted) return; // Check if widget is still on screen

        // 3. Navigate based on role
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
            // Role not found or is 'null'
            setState(() {
              _errorMessage = 'User role not found. Contact admin.';
            });
            authService.signOut(); // Log them out
        }
      }
    } catch (e) {
      // General error
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }

    // Stop loading
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the AppBar theme from main.dart
      appBar: AppBar(
        title: const Text('Login - JAYA FREIGHT'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your Logo Text
                Text(
                  'JAYA FREIGHT',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Please enter a valid email'
                      : null,
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (val) => val!.isEmpty
                      ? 'Enter password'
                      : null, // THIS IS THE FIXED LINE
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                const SizedBox(height: 10),

                // Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _login,
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
