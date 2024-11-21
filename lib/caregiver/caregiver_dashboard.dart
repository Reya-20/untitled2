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
import 'package:intl/intl.dart'; // Import the intl package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // This removes the debug banner
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
  List<Map<String, dynamic>> _alarms = []; // List to hold alarms

  @override
  void initState() {
    super.initState();
    _fetchAlarmData();
  }

  Future<void> _fetchAlarmData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://springgreen-rhinoceros-308382.hostingersite.com/get_alarm.php'));

      if (response.statusCode == 200) {
        // Log the response body to see the structure
        print('Response body: ${response.body}');

        // Decode the JSON response into a Map
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the 'success' key exists and if the 'data' key is a list
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            // Format the time for each alarm to 12-hour format with AM/PM
            _alarms =
                List<Map<String, dynamic>>.from(data['data']).map((alarm) {
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
            alarmData = _alarms;
            hasNoAlarms = alarmData.isEmpty;
          });
        } else {
          // Handle the case where the response data doesn't match the expected format
          print(
              'Error: Expected a list of alarms but found something else or success is false.');
          setState(() {
            _alarms = []; // Reset the alarms list if the data is not valid
          });
        }
      } else {
        print('Failed to load reminders. HTTP status: ${response.statusCode}');
        setState(() {
          _alarms = []; // Reset the alarms list in case of failure
        });
      }
    } catch (e) {
      print('Error fetching reminders: $e');
      setState(() {
        _alarms = []; // Reset the alarms list in case of error
      });
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
                    topLeft: Radius.circular(20), // Rounded top left corner
                    topRight: Radius.circular(20), // Rounded top right corner
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
          ]
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.blue.shade50, // Lighter shade for a softer background
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add some padding inside the card
          child: Row(
            children: [
              // Icon for Pill
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF39cdaf), // Matching color with the theme
                ),
                child: Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16), // Space between the icon and the text

              // Main Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alarm['pill_name']} for ${alarm['patient_name']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6), // Space between title and subtitle
                    Text(
                      'Reminder: ${alarm['reminder_message']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Time Text
              Text(
                _formatTime(alarm['time']),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF39cdaf), // Matching time color to theme
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      // Trim any leading or trailing spaces
      time = time.trim();

      // Use the DateFormat("h:mm a") to parse the time in 12-hour AM/PM format
      DateFormat format = DateFormat("h:mm a");

      // Parse the time string to DateTime
      DateTime alarmDate = format.parse(time);

      // Return the formatted time in the desired format (if you want to display it differently)
      return DateFormat('h:mm a').format(alarmDate);
    } catch (e) {
      print('Error formatting time: $e');
      return 'Invalid Time';
    }
  }
}
