import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
        scaffoldBackgroundColor: Colors.transparent,
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
  List<Map<String, dynamic>> _alarms = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicineNames();
    _fetchPatientNames();
    _fetchReminders();
  }

  @override
  void dispose() {
    _reminderMessageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicineNames() async {
    try {
      final response = await http.get(
        Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/pill_api/get_pill.php'),
      );
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
      final response = await http.get(
        Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/get_patient.php'),
      );
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
      final response = await http.get(
        Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com/get_alarm.php'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _alarms = List<Map<String, dynamic>>.from(data['data']).map((alarm) {
              return {
                ...alarm,
                'time': _formatTimeFromString(alarm['formatted_time'] ?? '00:00 AM'),
                'pill_name': alarm['pill_name'] ?? 'Unknown Pill',
                'patient_name': alarm['patient_name'] ?? 'Unknown Patient',
                'reminder_message': alarm['reminder_message'] ?? 'No Reminder Message',
              };
            }).toList();
          });
        } else {
          print('Error: Invalid data structure.');
        }
      } else {
        print('Failed to load reminders. HTTP status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reminders: $e');
    }
  }

  String _formatTimeFromString(String time) {
    try {
      final timeParts = time.split(' ');
      final formattedTime = '${timeParts[0]} ${timeParts[1]}';
      return formattedTime;
    } catch (e) {
      return 'Invalid time';
    }
  }

  Future<void> _submitData() async {
    final pillId = _selectedPillId;
    final patientId = _selectedPatientId;
    final reminderMessage = _reminderMessageController.text.trim();
    final time = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

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

          setState(() {
            _selectedPillId = null;
            _selectedPatientId = null;
            _reminderMessageController.clear();
            _selectedTime = TimeOfDay.now();
          });

          _fetchReminders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to add reminder')),
          );
        }
      } else {
        print('Failed to add reminder. HTTP status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please check your internet connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Medicine Reminder',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xFF006D77),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF39cdaf),
              Color(0xFF0E4C92),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            ..._alarms.map((alarm) => _buildAlarmCard(alarm)).toList(),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Manage Your Medicine Reminders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBottomSheet(context),
        backgroundColor: Color(0xFF006D77),
        child: Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
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
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF006D77),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                alarm['time'] ?? '00:00 AM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm['pill_name'] ?? 'Unknown Pill',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'To: ${alarm['patient_name'] ?? 'Unknown'} - ${alarm['reminder_message'] ?? 'No Reminder Message'}',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPillId,
                items: _medicineData.map((medicine) {
                  return DropdownMenuItem<String>(
                    value: medicine['pill_id'],
                    child: Text(medicine['pill_name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPillId = value),
                decoration: InputDecoration(
                  labelText: 'Select Pill',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPatientId,
                items: _patientData.map((patient) {
                  return DropdownMenuItem<String>(
                    value: patient['patient_id'],
                    child: Text(patient['patient_name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPatientId = value),
                decoration: InputDecoration(
                  labelText: 'Select Patient',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _reminderMessageController,
                decoration: InputDecoration(
                  labelText: 'Reminder Message',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Select Time',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                        text: '${_selectedTime.format(context)}'),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _submitData();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF006D77),
                    ),
                    child: Text('Save Reminder'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  }
