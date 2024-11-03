import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register.dart'; // Import your registration screen
import 'user/user_dashboard.dart'; // Import user dashboard
import 'caregiver/caregiver_dashboard.dart'; // Import caregiver dashboard

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);

    Future<void> _login() async {
      final email = _emailController.text;
      final password = _passwordController.text;

      // Check if email and password are provided
      if (email.isEmpty || password.isEmpty) {
        _errorMessage.value = 'Email and password cannot be empty';
        // Reset error message after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          _errorMessage.value = null;
        });
        return;
      }

      // Prepare the API request
      try {
        final response = await http.post(
          Uri.parse('http://192.168.1.9/alarm/account_api/login.php'), // Your API URL
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': email, 'password': password}),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['success']) {
            // Navigate based on role
            if (result['role'] == '0') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()), // User Dashboard
              );
            } else if (result['role'] == '1') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeCareScreen()), // Caregiver Dashboard
              );
            }
          } else {
            // Show error message if login fails
            _errorMessage.value = result['message'];
            // Reset error message after 5 seconds
            Future.delayed(Duration(seconds: 5), () {
              _errorMessage.value = null;
            });
          }
        } else {
          // Handle unexpected response
          _errorMessage.value = 'Error: ${response.statusCode}';
          // Reset error message after 5 seconds
          Future.delayed(Duration(seconds: 5), () {
            _errorMessage.value = null;
          });
        }
      } catch (e) {
        _errorMessage.value = 'Failed to connect to the server';
        // Reset error message after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          _errorMessage.value = null;
        });
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Icon at the top
                Icon(
                  Icons.medical_services, // Medical icon
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),

                // Welcome Text
                Text(
                  'Welcome to PillCare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Login Prompt
                const Text(
                  'Please log in to continue',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Error Message
                ValueListenableBuilder<String?>(
                  valueListenable: _errorMessage,
                  builder: (context, error, child) {
                    return error != null
                        ? Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8), // Background color for error message
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                        : SizedBox.shrink(); // Return empty widget if no error
                  },
                ),
                const SizedBox(height: 30),

                // Email Input Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Password Input Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF26394A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Registration Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateAccountScreen()),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
