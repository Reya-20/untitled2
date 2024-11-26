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
      home: AlarmHistoryScreen(),
    );
  }
}

class AlarmHistoryScreen extends StatefulWidget {
  @override
  _AlarmHistoryScreenState createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  List<Map<String, dynamic>> _alarms = [];

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://springgreen-rhinoceros-308382.hostingersite.com/alarm_history.php'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _alarms =
                List<Map<String, dynamic>>.from(data['data']).map((alarm) {
                  return {
                    ...alarm,
                    'time': _formatTimeFromString(
                        alarm['formatted_time'] ?? '00:00 AM'),
                    'pill_name': alarm['pill_name'] ?? 'Unknown Pill',
                    'patient_name': alarm['patient_name'] ?? 'Unknown Patient',
                    'reminder_message': alarm['reminder_message'] ??
                        'No Reminder Message',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alarm History',
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
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
            ),
          ],
        ),
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
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'To: ${alarm['patient_name'] ??
                        'Unknown'} - ${alarm['reminder_message'] ??
                        'No Reminder Message'}',
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
}
