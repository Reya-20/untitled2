import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Calendar package
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../include/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Speed Dial package
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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  int userRole = 1;
  List<Map<String, dynamic>> alarmData = [];
  bool hasNoAlarms = false;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _fetchAlarmData();
  }

  Future<void> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getInt('userRole') ?? 1;
    });
  }

  Future<void> _fetchAlarmData({String? patientId}) async {
    String url;
    if (patientId == null) {
      url = 'http://your_api_url/get_alarm.php?role=$userRole';
    } else {
      url =
      'http://your_api_url/get_alarm.php?patient_id=$patientId&role=$userRole';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            alarmData = data
                .map((item) =>
            {
              'patient_name': item['patient_name'],
              'medicine_name': item['pill_name'],
              'time': item['time'],
              'reminder_message': item['reminder_message'],
              'status_remark': item['status_remark'],
            })
                .toList();
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

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Notification'),
          content: Text('This is a notification message.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
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
            // Row to include the menu button before the calendar
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 10),
              // Positioning button
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  Spacer(),
                  // Notification button
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.white),
                    onPressed: _showNotificationDialog,
                  ),
                ],
              ),
            ),

            // Add space between menu button and calendar
            SizedBox(height: 5),

            // Calendar Widget
            TableCalendar(
              firstDay: DateTime.utc(2000),
              lastDay: DateTime.utc(2100),
              focusedDay: selectedDate,
              calendarFormat: CalendarFormat.month,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                });
                // Optionally, filter alarms based on `selectedDate`
              },
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF26394A),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF39cdaf),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(color: Colors.white),
                // Make calendar text white
                todayTextStyle: TextStyle(color: Colors.white),
                // Make today's date text white
                selectedTextStyle: TextStyle(
                    color: Colors.white), // Make selected day text white
              ),
            ),

            SizedBox(height: 20), // Add space between calendar and card

            // Alarm List
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
                  : Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50), // Rounded top left corner
                    topRight: Radius.circular(50), // Rounded top right corner
                  ),
                  color: Color(0xEAEBEBEF),
                ),
                child: ListView.builder(
                  itemCount: alarmData.length,
                  itemBuilder: (context, index) {
                    return _buildAlarmCard(alarmData[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Adjust position
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        backgroundColor: Color(0xFF26394A),
        children: [
          SpeedDialChild(
            child: Icon(Icons.medical_information),
            label: 'Add Pill',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicineScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.person_add),
            label: 'Add Patient',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.lock_clock),
            label: 'Make Alarm Reminder',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlarmScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.history),
            label: 'Medicine History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientScreen()),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // More rounded corners
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only show the "Today" label if alarm data is available
              if (alarm != null) // Check if there is alarm data
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  // Adds space below "Today"
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue, // You can change the color here
                    ),
                  ),
                ),
              // Alarm details
              Text("Patient: ${alarm['patient_name']}"),
              Text("Medicine: ${alarm['medicine_name']}"),
              Text("Time: ${alarm['time']}"),
              Text("Reminder: ${alarm['reminder_message']}"),
              Text("Status: ${alarm['status_remark']}"),
            ],
          ),
        ),
      ),
    );
  }
}