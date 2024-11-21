import 'package:flutter/material.dart';
import '../include/sidebar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for date formatting
import 'dart:async'; // Import for Timer
import 'dart:ui'; // For BackdropFilter


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int userRole = 0; // Set user role (0 or 1)
  List<dynamic> alarmData = [];
  bool hasNoAlarms = true; // Flag for no alarms
  bool _isDialogShowing = false; // Flag for dialog display
  Timer? _timer; // Timer for checking alarms
  Timer? _soundLoopTimer; // Timer for looping sound
  List<Map<String, dynamic>> _alarms = []; // List to hold fetched alarms
  TimeOfDay _selectedTime = TimeOfDay.now(); // Selected time for alarms

  @override
  void initState() {
    super.initState();
    _startCheckingTime(); // Start checking time immediately
    _fetchAlarmData(); // Fetch alarms on initialization
  }

  @override
  void dispose() {
    _timer?.cancel();
    _soundLoopTimer?.cancel(); // Stop looping sound timer on dispose
    super.dispose();
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


  Future<void> _startCheckingTime() async {
    print('Start checking time...'); // This line will output to the terminal
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await _checkAlarms();
    });
  }

  Future<void> _checkAlarms() async {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);

    print('Current time: $currentTime');

    for (var alarm in _alarms) {
      final alarmTime = alarm['time'] as String?;
      if (alarmTime != null) {
        final formattedAlarmTime = alarmTime.substring(0, 5);
        final alarmId = alarm['id'] is int ? alarm['id'] : int.tryParse(alarm['id'].toString()) ?? 0;

        // Check if the alarm is due and dialog is not already showing
        if (formattedAlarmTime == currentTime && !_isDialogShowing) {
          // Pop up the dialog first, before anything else
          _showAlarmDialog(alarmId);

          // After the dialog is shown, schedule the notification and start the sound
          await _scheduleNotification();

          // Start a timer to check if the dialog is still showing after 1 minute
          _timer = Timer(Duration(minutes: 3), () async {
            if (_isDialogShowing) {
              // If the dialog is still showing after 1 minute, mark the alarm as missed
              await _updateAlarmStatusToMissed(alarmId);
            }
          });

          // Cancel any previously running timer
          _timer?.cancel();
          break;
        }
      }
    }
  }



  Future<void> _updateAlarmStatusToMissed(int alarmId) async {
    try {
      final response = await http.put(
        Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/alarm_api/alarm_update_missed.php'), // Ensure this URL is correct
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': alarmId.toString(), 'status': '2'}, // Send as form data for missed
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('Alarm status updated to missed successfully');
        } else {
          print('Failed to update alarm status to missed: ${responseData['message']}');
        }
      } else {
        print('Failed to update alarm status to missed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating alarm status to missed: $e');
    }
  }

  Future<void> _scheduleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Play the default notification sound
      ticker: 'ticker',
      ongoing: true, // Keeps the notification active
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Trigger the notification initially
    await flutterLocalNotificationsPlugin.show(
      0,
      'Alarm',
      'Time to take your medicine',
      platformChannelSpecifics,
      payload: 'alarm_payload',
    );

    // Start a loop to continuously play sound every 5 seconds
    _soundLoopTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Alarm',
        'Time to take your medicine',
        platformChannelSpecifics,
        payload: 'alarm_payload',
      );
    });
  }

  void _showAlarmDialog(int alarmId) {
    if (!_isDialogShowing) {
      _isDialogShowing = true; // Ensure the flag is set to prevent multiple dialogs

      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside the dialog
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            title: Row(
              children: [
                Icon(Icons.alarm, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Alarm'),
              ],
            ),
            content: Text('It\'s time to take your medicine.'),
            actions: <Widget>[
              TextButton(
                child: Text('Take Meds'),
                onPressed: () async {
                  // Call to update the alarm status in the database
                  await _updateAlarmStatus(alarmId);

                  // Cancel the notification and stop the looping sound
                  await flutterLocalNotificationsPlugin.cancel(0);
                  _soundLoopTimer?.cancel(); // Stop the loop timer if it's running

                  // Dismiss the dialog
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Close the dialog
                  }

                  // Reset the dialog showing flag
                  _isDialogShowing = false;
                },
              ),
            ],
          );
        },
      ).then((_) {
        // Ensure _isDialogShowing is reset when the dialog is dismissed manually
        _isDialogShowing = false;
      });
    }
  }


  Future<void> _updateAlarmStatus(int alarmId) async {
    try {
      final response = await http.put(
        Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/alarm_api/alarm_update.php'), // Ensure this URL is correct
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}, // Use correct content type
        body: {'id': alarmId.toString(), 'status': '1'}, // Send as form data
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('Alarm status updated to 1 (meds taken) successfully');

          // Start a timer to reset the status to 0 after 1 second
          Timer(Duration(seconds: 3), () async {
            final resetResponse = await http.put(
              Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/alarm_api/alarm_update.php'), // Ensure this URL is correct
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {'id': alarmId.toString(), 'status': '0'}, // Reset to status 0
            );

            print('Reset response status: ${resetResponse.statusCode}');
            print('Reset response body: ${resetResponse.body}');
          });
        } else {
          print('Failed to update alarm status: ${responseData['message']}');
        }
      } else {
        print('Failed to update alarm status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating alarm status: $e');
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
      body: Stack(
        children: [
          // Background with gradient and transparent circles
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF39cdaf), Color(0xFF26394A)], // Gradient colors
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Adding transparent circles
          Positioned(
            top: 50,
            left: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Row to include the menu button
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
                    // Add other buttons here if needed
                  ],
                ),
              ),
              // Add a sidebox or any widget after the row
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.5),

              ),
              // Alarm content
              Expanded(
                child: hasNoAlarms
                    ? Center(
                  child: Text(
                    "No alarms found",
                    style: TextStyle(color: Colors.white),
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
        ],
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
