import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_pill_dashboard.dart';
import 'add_pill_name.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../include/sidebar.dart';

class PatientScreen extends StatefulWidget {
  @override
  _PatientScreenState createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> _patientList = [];
  int userRole = 1; // Set user role (0 or 1) based on your logic
  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    final url = Uri.parse('http://192.168.1.5/alarm/patient_api/get_patient.php');

    try {
      final response = await http.get(url);
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _patientList = (responseData as List<dynamic>).map((patient) => {
            'name': patient['patient_name'] ?? '',
            'username': patient['username'] ?? '',
            'password': patient['password'] ?? '',
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching patient data: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _addPatient() async {
    if (_nameController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      String name = _nameController.text;
      String username = _usernameController.text;
      String password = _passwordController.text;

      setState(() {
        _patientList.add({
          'name': name,
          'username': username,
          'password': password,
        });
        _nameController.clear();
        _usernameController.clear();
        _passwordController.clear();
      });

      await _uploadPatient(name, username, password);
    }
  }

  Future<void> _uploadPatient(String name, String username, String password) async {
    final url = Uri.parse('http://http://192.168.1.9/alarm/patient_api/post_patient.php');

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'patient_name': name,
          'username': username,
          'password': password,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Patient added successfully!'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${responseBody['message']}'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _deletePatient(int index) {
    setState(() {
      _patientList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
        title: Text('Add Patient'),
        backgroundColor: Color(0xFF0E4C92),
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        userRole: userRole,
      ), // Call the existing sidebar widget here
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Patient Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Username',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Add Patient'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: _patientList.isEmpty
                          ? Center(
                        child: Text(
                          "No patients added yet.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: _patientList.length,
                        itemBuilder: (context, index) {
                          final patient = _patientList[index];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                patient['name'],
                                style: TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              subtitle: Text(
                                'Username: ${patient['username']}\nPassword: ${patient['password']}',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePatient(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
