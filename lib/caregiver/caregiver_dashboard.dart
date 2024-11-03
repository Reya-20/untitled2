import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../include/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing user role

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set debug flag to false
      home: HomeCareScreen(),
    );
  }
}

class HomeCareScreen extends StatefulWidget {
  @override
  _HomeCareScreenState createState() => _HomeCareScreenState();
}

class _HomeCareScreenState extends State<HomeCareScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int userRole = 1; // Set user role (0 or 1) based on your logic
  List<Map<String, dynamic>> patientData = []; // List to hold patient data
  List<Map<String, dynamic>> alarmData = []; // List to hold alarm data
  bool hasNoAlarms = false; // Flag to track whether there are no alarms

  @override
  void initState() {
    super.initState();
    _getUserRole(); // Fetch user role from shared preferences or wherever it's stored
    _fetchPatientNames(); // Fetch patient names
    _fetchAlarmData(); // Fetch all alarms initially
  }

  Future<void> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getInt('userRole') ?? 1; // Default to 1 if not set
    });
  }

  Future<void> _fetchPatientNames() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.9/alarm/navbar_api/patient_list.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          patientData = data.map((item) => {
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

  Future<void> _fetchAlarmData({String? patientId}) async {
    String url;
    if (patientId == null) {
      // Fetch all alarms if patientId is null
      url = 'http://192.168.1.9/alarm/alarm_api/get_alarm.php?role=$userRole';
    } else {
      // Fetch alarms for the specific patient
      url = 'http://192.168.1.9/alarm/alarm_api/get_alarm.php?patient_id=$patientId&role=$userRole';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Alarm Data: $data'); // Debugging statement

        if (data is List && data.isNotEmpty) {
          setState(() {
            alarmData = data.map((item) => {
              'patient_name': item['patient_name'],
              'medicine_name': item['pill_name'], // This should match the alias
              'time': item['time'],
              'reminder_message': item['reminder_message'],
              'status_remark': item['status_remark'],
            } as Map<String, dynamic>).toList();
            hasNoAlarms = false; // Reset flag when alarms are present
            print('Alarms available');
          });
        } else {
          setState(() {
            alarmData = [];
            hasNoAlarms = true; // Set flag when no alarms are found
            print('No alarms found');
          });
        }
      } else {
        print('Failed to load alarm data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching alarm data: $e');
    }
  }

  void _onNameButtonPressed(String name, String? patientId) {
    if (patientId == null) {
      // Fetch all alarms if "All" button is pressed
      _fetchAlarmData();
    } else {
      // Fetch alarms for the selected patient
      _fetchAlarmData(patientId: patientId);
    }
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
        title: Text('PillCare'),
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        userRole: userRole,
      ),
      body: Column(
        children: [
          // Scrollable Names List including "All" button
          Container(
            height: 50,
            color: Colors.grey[200],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: patientData.length + 1, // +1 for "All" button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildNameButton("All", null);
                } else {
                  return _buildNameButton(
                    patientData[index - 1]['patient_name'],
                    patientData[index - 1]['patient_id'],
                  );
                }
              },
            ),
          ),
          Expanded(
            child: hasNoAlarms
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 150,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "You don’t have any medicine",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: alarmData.length,
              itemBuilder: (context, index) {
                return _buildAlarmCard(alarmData[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameButton(String name, String? patientId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: () {
          _onNameButtonPressed(name, patientId);
        },
        child: Text(name),
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for Icon and Medicine Name
            Row(
              children: [
                // Medicine Icon
                Icon(
                  Icons.medication,  // Medicine icon
                  size: 60,
                  color: Colors.blueAccent, // You can change the color as needed
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alarm['medicine_name'], // Medicine name
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Close button (optional)
                IconButton(
                  icon: Icon(Icons.roller_shades_closed_rounded, color: Colors.red),
                  onPressed: () {
                    // Handle delete logic
                  },
                ),
              ],
            ),
            SizedBox(height: 8),

            // Text for instructions
            Text(
              alarm['reminder_message'], // Static instruction (you can customize)
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),

            // Row for times a day and number of pills
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey),
                SizedBox(width: 5),
                Text(
                    alarm['time'],
                    style: TextStyle(fontSize: 16)),
                SizedBox(width: 15),
              ],
            ),
            SizedBox(height: 10),

            // Status like "Pending"
            Text(
              alarm['status_remark'],
              style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
