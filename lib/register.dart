import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'start.dart';

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

  String? errorMessage;
  bool isLoading = false;

  Future<void> _createAccount() async {
    setState(() {
      isLoading = true;
    });

    final String firstName = firstNameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "All fields must be filled out.";
        isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Passwords do not match.";
        isLoading = false;
      });
      return;
    }

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
      Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com/register.php'),
      body: data,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created successfully")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        setState(() {
          errorMessage = "Failed to create account: ${result['message']}";
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = "Error: ${response.statusCode}";
        isLoading = false;
      });
    }
  }

  Widget _buildUsernameField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
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
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            '@pillcare',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
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
                const SizedBox(height: 10.0),
                if (errorMessage != null)
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
                _buildUsernameField(),
                const SizedBox(height: 10.0),
                _buildTextField('Password', passwordController, isPassword: true),
                const SizedBox(height: 10.0),
                _buildTextField('Confirm Password', confirmPasswordController, isPassword: true),
                const SizedBox(height: 30.0),
                ElevatedButton(
                  onPressed: isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 100.0),
                    backgroundColor: Color(0xFF39cdaf),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Text(
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
