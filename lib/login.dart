import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user/user_dashboard.dart'; // Import the user_dashboard.dart file
import 'caregiver/caregiver_dashboard.dart'; // Import the caregiver_dashboard.dart file

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Check if username and password are provided
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Username and password cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare the API request
    try {
      print('Attempting to log in with username: $username and password: $password');
      final response = await http.post(
        Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com//login.php'), // Your API URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle unexpected response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to connect to the server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Light gray background
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // The rounded rectangle container at the top with no margin
                Container(
                  height: 180, // Adjust height based on your design
                  decoration: const BoxDecoration(
                    color: Color(0xFF26394A), // Dark blue color
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                // Display the logo with a border
                Column(
                  children: [
                    const SizedBox(height: 50), // Spacing between the logo and text
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sign in to your account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 5), // Space at the top
                    Container(
                      width: 180, // Adjust the width based on your design
                      height: 180, // Adjust the height based on your design
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF26394A), // Border color
                          width: 4, // Border width
                        ),
                        borderRadius: BorderRadius.circular(10), // Rounded corners for the border
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10), // Rounded corners for the image
                        child: Image.asset(
                          'asset/image/logo.png', // Path to the logo image
                          fit: BoxFit.cover, // Ensure the image covers the container
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Space before "PillCare" text
                    // Display the "PillCare" text with custom styling
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pill',
                            style: TextStyle(
                              color: Color(0xFF26394A),
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Care',
                            style: TextStyle(
                              color: Color(0xFF39cdaf),
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50), // Spacing after header and logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20), // Padding for form fields
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Username Field
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: 'Enter Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20), // Space between text fields
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'Enter Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 10), // Space before sign in button
                  // Sign In Button
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26394A), // Dark blue color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
