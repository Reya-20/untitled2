import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Calendar package
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../include/sidebar.dart';
import 'Alarm_History.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Speed Dial package
import 'add_patient_name.dart';
import 'add_pill_name.dart';
import 'add_pill_dashboard.dart';
import 'package:intl/intl.dart'; // Add this import for time parsing


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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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
      final response = await http.get(Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com/get_alarm.php'));

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');

        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _alarms = List<Map<String, dynamic>>.from(data['data']).map((alarm) {
              String time = alarm['formatted_time'] ?? '00:00 AM';
              String reminderMessage = alarm['reminder_message'] ?? '';
              String patientName = alarm['patient_name'] ?? 'Unknown';
              String pillName = alarm['pill_name'] ?? 'Unknown Pill';

              return {
                'id': alarm['id'],
                'time': time,
                'reminder_message': reminderMessage,
                'patient_name': patientName,
                'pill_name': pillName,
                'status_remark': alarm['status_remark'] ?? 'Pending',
              };
            }).toList();
          });
        } else {
          print('Error: Expected a list of alarms but found something else or success is false.');
          setState(() {
            _alarms = [];
          });
        }
      } else {
        print('Failed to load reminders. HTTP status: ${response.statusCode}');
        setState(() {
          _alarms = [];
        });
      }
    } catch (e) {
      print('Error fetching reminders: $e');
      setState(() {
        _alarms = [];
      });
    }
  }

  void _showNotificationDialog() async {
    // Fetch pill data from the server
    try {
      final response = await http.get(Uri.parse('https://springgreen-rhinoceros-308382.hostingersite.com/get_pill_count.php'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['pill_data'] is List) {
          // Iterate over the pill data to find pills with low quantities
          String notificationMessage = '';

          for (var pill in data['pill_data']) {
            String pillQuantityStr = pill['pill_quantity']?.toString() ?? '0'; // Ensure it's a string
            int pillQuantity = int.tryParse(pillQuantityStr) ?? 0; // Convert to int safely

            String pillName = pill['pill_name'] ?? 'Unknown Pill';
            String containerId = pill['container'] ?? 'Unknown Container';

            // Check if the pill quantity is 2 or less
            if (pillQuantity <= 2 && pillQuantity > 0) {
              notificationMessage += 'Warning: $pillName in Container $containerId has low quantity ($pillQuantity pills remaining).\n';
            } else if (pillQuantity == 0) {
              notificationMessage += 'Alert: $pillName in Container $containerId is out of stock.\n';
            }
          }

          if (notificationMessage.isEmpty) {
            notificationMessage = 'All pills are well stocked!';
          }

          // Show dialog with the appropriate message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Pill Stock Notification'),
                content: Text(notificationMessage),
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
        } else {
          // If the data format is incorrect
          print('Error: Pill data is missing or malformed.');
        }
      } else {
        print('Failed to fetch pill data. HTTP status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pill data: $e');
    }
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
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.white),
                    onPressed: _showNotificationDialog,
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            TableCalendar(
              firstDay: DateTime.utc(2000),
              lastDay: DateTime.utc(2100),
              focusedDay: selectedDate,
              calendarFormat: CalendarFormat.month,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                });
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
                todayTextStyle: TextStyle(color: Colors.white),
                selectedTextStyle: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
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
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Color(0xEAEBEBEF),
                ),
                child: ListView.builder(
                  itemCount: _alarms.length,
                  itemBuilder: (context, index) {
                    return _buildAlarmCard(_alarms[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            label: 'Create Reminder',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlarmScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.book),
            label: 'View History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlarmHistoryScreen()),
              );
            },
          ),
        ],
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
            // Time display
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF006D77),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                alarm['time'] ?? '00:00 AM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 20),
            // Expanded content for pill name and reminder message
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
            // Status Remark display on the right
            Text(
              alarm['status_remark'] ?? 'No Status',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _parseTime(String time) {
    try {
      // Ensure the time is not empty and valid
      if (time.isNotEmpty) {
        var format = DateFormat("h:mm a"); // 12-hour format (e.g., 11:30 AM)
        var parsedTime = format.parse(time);
        return DateFormat("HH:mm").format(parsedTime); // Convert to 24-hour format
      } else {
        return '00:00 AM'; // Return default time if input is invalid or empty
      }
    } catch (e) {
      print('Error parsing time: $e');
      return '00:00 AM'; // Fallback to default time
    }
  }

  bool _isToday(String alarmTime) {
    try {
      // Parse the alarm time with the correct format
      var format = DateFormat("h:mm a"); // 12-hour format (e.g., 11:30 AM)
      DateTime alarmDate = format.parse(alarmTime);
      DateTime currentDate = DateTime.now();

      // Compare date without time
      return currentDate.year == alarmDate.year &&
          currentDate.month == alarmDate.month &&
          currentDate.day == alarmDate.day;
    } catch (e) {
      print('Error comparing dates: $e');
      return false;
    }
  }
}
