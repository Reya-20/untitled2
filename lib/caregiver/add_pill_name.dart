import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'dart:convert'; // Added for JSON decoding
import 'add_pill_dashboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'add_patient_name.dart';
import '../include/sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MedicineScreen(),
    );
  }
}

class MedicineScreen extends StatefulWidget {
  @override
  _MedicineScreenState createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _medicineController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<String> _medicineList = [];
  int userRole = 1; // Set user role (0 or 1) based on your logic

  @override
  void initState() {
    super.initState();
    _fetchMedicines(); // Fetch medicines when the screen is loaded
  }

  // Function to fetch medicines from the server
  Future<void> _fetchMedicines() async {
    final url = Uri.parse('http://192.168.1.5/alarm/pill_api/get_pill.php'); // Replace with your actual URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _medicineList = responseData.map((pill) => pill['pill_name'].toString()).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching medicine data: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to add medicine locally and send data to server
  void _addMedicine() async {
    if (_medicineController.text.isNotEmpty) {
      String medicineName = _medicineController.text;

      // Add medicine locally
      setState(() {
        _medicineList.add(medicineName);
        _medicineController.clear();
      });

      // Upload medicine to the server
      await uploadMedicines([medicineName]); // Send a list with the new medicine
    }
  }

  // Function to upload medicine names to the server
  Future<void> uploadMedicines(List<String> medicineNames) async {
    final url = Uri.parse('http://192.168.1.5/alarm/pill_api/post_pill.php'); // Replace with your actual URL

    try {
      final response = await http.post(
        url,
        body: {
          'medicine_names': json.encode(medicineNames), // Send the list as JSON
        },
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      );

      print('Response status: ${response.statusCode}'); // Log response status
      print('Response body: ${response.body}'); // Log response body

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Medicine added successfully!'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${responseBody['message']}'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to delete medicine
  void _deleteMedicine(int index) {
    setState(() {
      _medicineList.removeAt(index);
    });
    // You can also make a server call here to delete the item from the server if needed
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
        title: Text('Add Medicine'),
        backgroundColor: Color(0xFF0E4C92),
      ),
      drawer: CustomDrawer(
        scaffoldKey: _scaffoldKey,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        userRole: userRole,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Medicine Name Input Field
            TextField(
              controller: _medicineController,
              decoration: InputDecoration(
                hintText: 'Medicine Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Add Medicine Button
            ElevatedButton(
              onPressed: _addMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Add Medicine'),
            ),
            SizedBox(height: 20),
            // Medicine List Container
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: _medicineList.isEmpty
                          ? Center(
                        child: Text(
                          "No medicines added yet.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: _medicineList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                _medicineList[index],
                                style: TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMedicine(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
