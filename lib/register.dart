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

  String? errorMessage; // State variable for error message

  Future<void> _createAccount() async {
    final String firstName = firstNameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    // Validate input fields
    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "All fields must be filled out.";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Passwords do not match.";
      });
      return;
    }

    // Clear the error message if validation passes
    setState(() {
      errorMessage = null;
    });

    final Map<String, String> data = {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'password': password,
      'confirm_password': confirmPassword,
    };

    final response = await http.post(
      Uri.parse('http://192.168.1.9/alarm/account_api/register.php'),
      body: data,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created successfully")),
        );
      } else {
        setState(() {
          errorMessage = "Failed to create account: ${result['message']}";
        });
      }
    } else {
      setState(() {
        errorMessage = "Error: ${response.statusCode}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF26394A),
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                'Let\'s create your account',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30.0),
              CircleAvatar(
                radius: 50.0,
                backgroundImage: AssetImage('asset/image/5-removebg-preview.png'),
              ),
              const SizedBox(height: 20.0),
              Text(
                'PillCare',
                style: TextStyle(
                  fontSize: 34.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10.0), // Space for the error message
              if (errorMessage != null) // Display the error message if it's not null
                Container(
                  margin: const EdgeInsets.only(bottom: 20.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 10.0),
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
                  backgroundColor: Color(0xFF39cdaf),
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
              const SizedBox(height: 40.0),
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
          color: Colors.white,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF39cdaf)),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
