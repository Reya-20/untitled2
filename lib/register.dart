import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CreateAccountScreen(),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> _createAccount() async {
    final String firstName = firstNameController.text;
    final String lastName = lastNameController.text;
    final String username = usernameController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (password != confirmPassword) {
      // Show an error message if passwords don't match
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // Prepare data for the request
    final Map<String, String> data = {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'password': password,
      'confirm_password': confirmPassword, // Added confirm_password
    };

    // Send the POST request
    final response = await http.post(
      Uri.parse('http://192.168.1.5/alarm/account_api/register.php'),
      body: data,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      // Handle success or failure response here
      if (result['success']) { // Check for 'success' key
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create account: ${result['message']}")),
        );
      }
    } else {
      // Handle server error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0E4C92),
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // Add SingleChildScrollView here
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20.0),
              Text(
                'Create an Account!',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0E4C92),
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                'Let\'s create your account',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30.0),
              CircleAvatar(
                radius: 50.0,
                backgroundImage: AssetImage('asset/image/logo.png'),
              ),
              const SizedBox(height: 20.0),
              Text(
                'PillCare',
                style: TextStyle(
                  fontSize: 34.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0E4C92),
                ),
              ),
              const SizedBox(height: 30.0),
              _buildTextField('First Name', firstNameController),
              const SizedBox(height: 10.0),
              _buildTextField('Last Name', lastNameController),
              const SizedBox(height: 10.0),
              _buildTextField('Username', usernameController),
              const SizedBox(height: 10.0),
              _buildTextField('Password', passwordController, isPassword: true),
              const SizedBox(height: 10.0),
              _buildTextField('Confirm Password', confirmPasswordController, isPassword: true),
              const SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: _createAccount,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 100.0),
                  backgroundColor: Color(0xFF0E4C92),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0E4C92)),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
