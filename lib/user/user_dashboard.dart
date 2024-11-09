import 'package:flutter/material.dart';
import '../include/sidebar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for date formatting
import 'dart:async'; // Import for Timer

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
    String url = 'http://springgreen-rhinoceros-308382.hostingersite.com/alarm/alarm_api/getalarm.php'; // Ensure the correct URL

    try {
      print('Fetching alarm data...');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Data fetched: $data'); // Print fetched data
        if (data is List) {
          setState(() {
            alarmData = data.map((item) => {
              'id': item['id'] ?? 0, // Make sure to include the id
              'patient_name': item['patient_name'] ?? 'Unknown',
              'medicine_name': item['pill_name'] ?? 'No Name',
              'time': item['time'] ?? 'Not Set',
              'reminder_message': item['reminder_message'] ?? 'No Message',
              'status_remark': item['status_remark'] ?? 'Pending',
            }).toList();
            hasNoAlarms = alarmData.isEmpty; // Update flag based on data
            _alarms = alarmData.cast<Map<String, dynamic>>(); // Cast to List<Map<String, dynamic>>
          });
          if (!hasNoAlarms) {
            _startCheckingTime(); // Start checking time only if there are alarms
          }
        } else {
          print('No alarm data found');
          setState(() {
            alarmData = [];
            hasNoAlarms = true; // Set flag when no alarms are found
          });
        }
      } else {
        print('Failed to load alarm data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching alarm data: $e');
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
          hasNoAlarms
              ? Center(child: Text("No alarms found"))
              : Expanded(
            child: ListView.builder(
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
            Row(
              children: [
                Icon(Icons.medication, size: 60, color: Colors.blueAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alarm['medicine_name'] ?? 'No Name', // Default if null
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            Text(alarm['reminder_message'] ?? 'No Message', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey),
                SizedBox(width: 5),
                Text(alarm['time'] ?? 'Not Set', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 10),
            Text(alarm['status_remark'] ?? 'Pending', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
