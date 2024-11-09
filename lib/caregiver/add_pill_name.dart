import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<String> _medicineList = [];
  int userRole = 1; // Set user role (0 or 1) based on your logic
  int? selectedContainer; // Variable to hold selected container number
  int _medicineCount = 0; // Medicine count for the dialog

  @override
  void initState() {
    super.initState();
    _fetchMedicines(); // Fetch medicines when the screen is loaded
  }

  // Function to fetch medicines from the server
  Future<void> _fetchMedicines() async {
    final url = Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/pill_api/get_pill.php'); // Replace with your actual URL

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
    if (_medicineController.text.isNotEmpty && selectedContainer != null) {
      String medicineName = _medicineController.text;

      // Add medicine locally
      setState(() {
        _medicineList.add(medicineName);
        _medicineController.clear();
        selectedContainer = null; // Reset the selected container after adding
      });

      // Upload medicine to the server
      await uploadMedicines([medicineName]); // Send a list with the new medicine
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter medicine name and select a container'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to upload medicine names to the server
  Future<void> uploadMedicines(List<String> medicineNames) async {
    final url = Uri.parse('http://springgreen-rhinoceros-308382.hostingersite.com/alarm/pill_api/post_pill.php'); // Replace with your actual URL

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

  // Function to show the dialog with a dropdown for container selection
  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Medicine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _medicineController,
                decoration: InputDecoration(
                  labelText: 'Enter Medicine Name',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Medicine Count:'),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_medicineCount > 0) _medicineCount--;
                          });
                        },
                      ),
                      Text('$_medicineCount'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _medicineCount++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButton<int>(
                value: selectedContainer,
                hint: Text("Select Container"),
                items: List.generate(5, (index) {
                  return DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text('Container ${index + 1}'),
                  );
                }),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedContainer = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _addMedicine(); // Add the medicine when this is pressed
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Add"),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39cdaf), Color(0xFF26394A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // New Layout with 5 Containers
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 8, // More pronounced shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xFF26394A), // Soft container background
                      ),
                      child: Center(
                        child: Text(
                          'Container ${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _showDialog, // Show the dialog when pressed
                child: Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF39cdaf),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
