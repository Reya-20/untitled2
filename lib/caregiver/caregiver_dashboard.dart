import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../include/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Import Speed Dial package
import 'add_patient_name.dart';
import 'add_pill_name.dart';
import 'add_pill_dashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeCareScreen(),
      theme: ThemeData(
        primaryColor: Color(0xFF0E4C92),
        hintColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(background: Color(0xFF0E4C92)),
      ),
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
  int userRole = 1;
  List<Map<String, dynamic>> patientData = [];
  List<Map<String, dynamic>> alarmData = [];
  bool hasNoAlarms = false;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _fetchPatientNames();
    _fetchAlarmData();
  }

  Future<void> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getInt('userRole') ?? 1;
    });
  }

  Future<void> _fetchPatientNames() async {
    try {
      final response = await http.get(Uri.parse('http://your_api_url/patient_list.php'));
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
      url = 'http://your_api_url/get_alarm.php?role=$userRole';
    } else {
      url = 'http://your_api_url/get_alarm.php?patient_id=$patientId&role=$userRole';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            alarmData = data.map((item) => {
              'patient_name': item['patient_name'],
              'medicine_name': item['pill_name'],
              'time': item['time'],
              'reminder_message': item['reminder_message'],
              'status_remark': item['status_remark'],
            }).toList();
            hasNoAlarms = false;
          });
        } else {
          setState(() {
            alarmData = [];
            hasNoAlarms = true;
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
      _fetchAlarmData();
    } else {
      _fetchAlarmData(patientId: patientId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Color(0xFF26394A),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),

      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        userRole: userRole,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: patientData.length + 1,
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
                    Icon(Icons.calendar_today, size: 150, color: Colors.blue),
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
            // Aligning SpeedDial to the right side of the screen
            Align(
              alignment: Alignment.bottomRight,
              child: SpeedDial(
                animatedIcon: AnimatedIcons.menu_close,
                animatedIconTheme: IconThemeData(size: 22.0),
                backgroundColor: Color(0xFF26394A),
                foregroundColor: Colors.white,
                onOpen: () => print('Speed dial opened'),
                onClose: () => print('Speed dial closed'),
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.lock_clock),
                    label: 'Make Alarm',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AlarmScreen()),
                      );
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.medical_information),
                    label: 'Add Medicine',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MedicineScreen()),
                      );
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.family_restroom),
                    label: 'Add Family Members',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PatientScreen()),
                      );
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.history),
                    label: 'Medicine History',
                    //onTap: () {
                      // Trigger the Medicine History screen
                    //  Navigator.push(
                     //   context,
                    //    MaterialPageRoute(builder: (context) => MedicineHistoryScreen()),
                    //  );
                //    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNameButton(String name, String? patientId) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10), // Add top margin
      child: ElevatedButton(
        onPressed: () {
          _onNameButtonPressed(name, patientId);
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black, // Set text color to black
          backgroundColor: Colors.white, // Set background color to white
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Apply a smaller borderRadius
          ),
        ),
        child: Text(name),
      ),
    );
  }



  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    return Card(
      color: Colors.transparent,
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
            Row(
              children: [
                Icon(Icons.medication, size: 60, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alarm['medicine_name'],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.roller_shades_closed_rounded, color: Colors.red),
                  onPressed: () {
                    // Handle delete logic
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              alarm['reminder_message'],
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time: ${alarm['time']}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  'Status: ${alarm['status_remark']}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
