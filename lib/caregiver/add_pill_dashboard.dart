import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../include/sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF26394A),
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Arial',
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
  final _medicineNameController = TextEditingController();
  final _reminderMessageController = TextEditingController();
  String? _selectedPillId;
  String? _selectedPatientId;
  List<Map<String, dynamic>> _medicineData = [];
  List<Map<String, dynamic>> _patientData = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicineNames();
    _fetchPatientNames();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _reminderMessageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicineNames() async {
    try {
      final response = await http.get(Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/pill_api/get_pill.php'));
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
      final response = await http.get(Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/patient_api/get_patient.php'));
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

  Future<void> _submitData() async {
    final pillId = _selectedPillId;
    final patientId = _selectedPatientId;
    final reminderMessage = _reminderMessageController.text;
    final time = '${_selectedTime.hour}:${_selectedTime.minute}';

    if (pillId == null || patientId == null || reminderMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final uri = Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/alarm_api/alarm_api.php');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder added successfully')),
      );

      // Clear fields after successful submission
      setState(() {
        _selectedPillId = null;
        _selectedPatientId = null;
        _reminderMessageController.clear();
        _selectedTime = TimeOfDay.now(); // Reset to the current time
      });
    } else {
      print('Failed to add reminder: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
        title: Text(
          'Medicine Reminder',
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        backgroundColor: Color(0xFF26394A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildMedicineSelector(),
            _buildPatientSelector(),
            _buildMessageField(),
            _buildTimeSelectorContainer(),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF26394A),
                padding: EdgeInsets.symmetric(vertical: 15.0),
              ),
              child: Text(
                'Add Reminder',
                style: TextStyle(fontSize: 16, color: Colors.white), // Set text color to white
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineSelector() {
    return _buildCard(
      title: 'Select Medicine',
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedPillId,
        hint: Text('Choose a medicine'),
        items: _medicineData.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['pill_id'].toString(),
            child: Text(item['pill_name']),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedPillId = newValue;
          });
        },
      ),
    );
  }

  Widget _buildPatientSelector() {
    return _buildCard(
      title: 'Select Patient',
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedPatientId,
        hint: Text('Choose a patient'),
        items: _patientData.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['patient_id'].toString(),
            child: Text(item['patient_name']),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedPatientId = newValue;
          });
        },
      ),
    );
  }

  Widget _buildMessageField() {
    return _buildCard(
      title: 'Reminder Message',
      child: TextField(
        controller: _reminderMessageController,
        decoration: InputDecoration(
          hintText: 'Enter reminder message',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.note, color: Color(0xFF26394A)),
        ),
      ),
    );
  }

  Widget _buildTimeSelectorContainer() {
    return _buildCard(
      title: 'Select Time',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedTime.format(context),
            style: TextStyle(fontSize: 18.0),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _selectTime(context);
            },
            icon: Icon(Icons.access_time),
            label: Text('Pick Time'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 3.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            child,
          ],
        ),
      ),
    );
  }
}
