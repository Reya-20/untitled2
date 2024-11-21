import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import the intl package
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF006D77),
        scaffoldBackgroundColor: Colors.transparent, // Set transparent background for Scaffold
        fontFamily: 'Roboto',
      ),
      home: AlarmScreen(),
    );
  }
}

class AlarmScreen extends StatefulWidget {
  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _reminderMessageController = TextEditingController();
  String? _selectedPillId;
  String? _selectedPatientId;
  List<Map<String, dynamic>> _medicineData = [];
  List<Map<String, dynamic>> _patientData = [];
  List<Map<String, dynamic>> _alarms = []; // List to hold alarms

  @override
  void initState() {
    super.initState();
    _fetchMedicineNames();
    _fetchPatientNames();
    _fetchReminders(); // Load reminders
  }

  @override
  void dispose() {
    _reminderMessageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicineNames() async {
    try {
      final response = await http.get(Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/pill_api/get_pill.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _medicineData = data.map((item) => {
            'pill_id': item['pill_id'],
            'pill_name': item['pill_name']
          }).toList();
        });
      } else {
        print('Failed to load medicine names: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching medicine names: $e');
    }
  }

  Future<void> _fetchPatientNames() async {
    try {
      final response = await http.get(Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/get_patient.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _patientData = data.map((item) => {
            'patient_id': item['patient_id'],
            'patient_name': item['patient_name']
          }).toList();
        });
      } else {
        print('Failed to load patient names: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching patient names: $e');
    }
  }
  Future<void> _fetchReminders() async {
    try {
      final response = await http.get(Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com/get_reminder.php'));

      if (response.statusCode == 200) {
        // Log the response body to see the structure
        print('Response body: ${response.body}');

        // Decode the JSON response into a Map
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the 'data' key exists and if it's a list
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            // Format the time for each alarm to 12-hour format with AM/PM
            _alarms = List<Map<String, dynamic>>.from(data['data']).map((alarm) {
              // Ensure no null values are being used, provide default values where necessary

              String time = alarm['formatted_time'] ?? '00:00 AM'; // Provide default time if null
              String reminderMessage = alarm['reminder_message'] ?? ''; // Provide empty string if null
              String patientName = alarm['patient_name'] ?? 'Unknown'; // Provide default name if null
              String pillName = alarm['pill_name'] ?? 'Unknown Pill'; // Provide default pill name if null

              return {
                'id': alarm['id'],
                'time': time, // Time is already formatted in the response
                'reminder_message': reminderMessage,
                'patient_name': patientName,
                'pill_name': pillName,
              };
            }).toList();
          });
        } else {
          print('Error: Expected a list of alarms but found something else.');
        }
      } else {
        print('Failed to load reminders. HTTP status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reminders: $e');
    }
  }


  Future<void> _submitData() async {
    final pillId = _selectedPillId;
    final patientId = _selectedPatientId;
    final reminderMessage = _reminderMessageController.text.trim();
    final time = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    // Validate inputs
    if (pillId == null || patientId == null || reminderMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final uri = Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com/add_reminder.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'pill_id': pillId,
          'patient_id': patientId,
          'message': reminderMessage,
          'time': time,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reminder added successfully')),
          );

          // Reset the form and state
          setState(() {
            _selectedPillId = null;
            _selectedPatientId = null;
            _reminderMessageController.clear();
            _selectedTime = TimeOfDay.now();
          });

          // Refresh the reminders after submission
          _fetchReminders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to add reminder')),
          );
        }
      } else {
        print('Failed to add reminder. HTTP status: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reminder. Please try again later.')),
        );
      }
    } catch (e) {
      print('Error submitting reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please check your internet connection.')),
      );
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Reminder',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              _buildMedicineSelector(),
              SizedBox(height: 15),
              _buildPatientSelector(),
              SizedBox(height: 15),
              _buildMessageField(),
              SizedBox(height: 15),
              _buildTimeSelectorContainer(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _submitData();
                  Navigator.of(context).pop(); // Close the bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF006D77),
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Save Reminder',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Ensures icon color is white
      ),
      extendBodyBehindAppBar: true, // This ensures the body content is behind the AppBar
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            SizedBox(height: 80), // Add SizedBox to push content down below the app bar

            // Add a label above the alarm cards
            Center(
              child: Text(
                'Manage Your Medicine Reminders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            SizedBox(height: 15), // Add space between the label and first card

            // Display the list of alarms
            ..._alarms.map((alarm) => _buildAlarmCard(alarm)).toList(),

            SizedBox(height: 20),

            // Centered message for adding a new alarm

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBottomSheet(context),
        backgroundColor: Color(0xFF006D77),
        child: Icon(Icons.add, size: 30),
      ),
    );
  }


  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    bool isActive = alarm['status'] == 'active';
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side: Time (bold and large), with a colored background
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF006D77), // Set background color for the time section
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${alarm['time']}',
                style: TextStyle(
                  fontSize: 22, // Large font size for time
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for contrast
                ),
              ),
            ),

            // Horizontal Space after Time
            SizedBox(width: 20),

            // Right side: Medicine name and reminder message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name
                  Text(
                    alarm['pill_name'],
                    style: TextStyle(
                      fontSize: 18, // Slightly smaller than time
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5), // Space between the medicine name and message

                  // Reminder message and patient name
                  Text(
                    'To: ${alarm['patient_name']} - ${alarm['reminder_message'] ?? 'No reminder message'}',
                    style: TextStyle(
                      fontSize: 14, // Normal size for the message
                      color: Colors.black54,
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

  Widget _buildMedicineSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: 'Select Medicine'),
      value: _selectedPillId,
      items: _medicineData.map((pill) {
        return DropdownMenuItem<String>(
          value: pill['pill_id'],
          child: Text(pill['pill_name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPillId = value;
        });
      },
    );
  }

  Widget _buildPatientSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: 'Select Patient'),
      value: _selectedPatientId,
      items: _patientData.map((patient) {
        return DropdownMenuItem<String>(
          value: patient['patient_id'],
          child: Text(patient['patient_name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPatientId = value;
        });
      },
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _reminderMessageController,
      decoration: InputDecoration(labelText: 'Reminder Message'),
      maxLines: 3,
    );
  }

  Widget _buildTimeSelectorContainer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Time: ${_selectedTime.format(context)}',
          style: TextStyle(fontSize: 16),
        ),
        IconButton(
          icon: Icon(Icons.access_time),
          onPressed: _selectTime,
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (newTime != null && newTime != _selectedTime) {
      setState(() {
        _selectedTime = newTime;
      });
    }
  }
}
