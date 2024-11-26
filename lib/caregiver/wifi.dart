import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateWifiPage extends StatefulWidget {
  @override
  _UpdateWifiPageState createState() => _UpdateWifiPageState();
}

class _UpdateWifiPageState extends State<UpdateWifiPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _updateWifiSettings() async {
    final String apiUrl = 'https://your-backend-url/update_wifi.php'; // Replace with your actual API URL

    // Send the SSID and password to the backend
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'ssid': _ssidController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WiFi settings updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update WiFi settings')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update WiFi Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centering the content vertically
            children: <Widget>[
              TextField(
                controller: _ssidController,
                decoration: InputDecoration(
                  labelText: 'SSID',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7), // Light background for text field
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7), // Light background for text field
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateWifiSettings,
                child: Text('Update'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20), backgroundColor: Color(0xFF39cdaf), // Button color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
