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
  final TextEditingController _medicineCountController = TextEditingController(); // Controller for medicine count
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<String> _medicineList = [];
  int userRole = 1; // Set user role (0 or 1) based on your logic
  int? selectedContainer; // Variable to hold selected container number

  @override
  void initState() {
    super.initState();
    _fetchMedicines(); // Fetch medicines when the screen is loaded
  }

  // Function to fetch medicines from the server
  Future<void> _fetchMedicines() async {
    final url = Uri.parse(
        'http://springgreen-rhinoceros-308382.hostingersite.com/pill_api/get_pill.php'); // Replace with your actual URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _medicineList =
              responseData.map((pill) => pill['pill_name'].toString()).toList();
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

  void _addMedicine() async {
    if (_medicineController.text.isNotEmpty &&
        _medicineCountController.text.isNotEmpty &&
        selectedContainer != null) {
      String medicineName = _medicineController.text;

      // Validate the medicine count input
      int medicineCount;
      try {
        medicineCount = int.parse(_medicineCountController.text); // Try to parse the count as an integer
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please enter a valid number for medicine count'),
          backgroundColor: Colors.red,
        ));
        return; // Exit the method if the input is invalid
      }

      // Upload medicine to the server
      bool success = await uploadMedicines([medicineName], medicineCount, selectedContainer!);

      // If the upload is successful, add the medicine to the list
      if (success) {
        setState(() {
          _medicineList.add(medicineName);
          _medicineController.clear();
          _medicineCountController.clear(); // Clear the medicine count input
          selectedContainer = null; // Reset the selected container after adding
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter medicine name, count, and select a container'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to upload medicine names to the server
  Future<bool> uploadMedicines(List<String> medicineNames, int pillCount, int container) async {
    final url = Uri.parse(
        'http://springgreen-rhinoceros-308382.hostingersite.com/post_pill.php'); // Replace with your actual URL

    try {
      final response = await http.post(
        url,
        body: {
          'medicine_name': medicineNames[0], // Send single medicine name
          'pill_count': pillCount.toString(), // Include pill count
          'container': container.toString(), // Include selected container
        },
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Medicine added successfully!'),
            backgroundColor: Colors.green,
          ));
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${responseBody['message']}'),
            backgroundColor: Colors.red,
          ));
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  // Function to delete medicine
  void _deleteMedicine(int index) {
    setState(() {
      _medicineList.removeAt(index);
    });
    // You can also make a server call here to delete the item from the server if needed
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
          ),
          title: Text(
            "Add Medicine",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medicine name input
                TextField(
                  controller: _medicineController,
                  decoration: InputDecoration(
                    labelText: 'Enter Medicine Name',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Medicine count input (as an input field)
                TextField(
                  controller: _medicineCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Medicine Count',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Container selection dropdown
                DropdownButton<int>(
                  value: selectedContainer,
                  hint: Text("Select Container"),
                  isExpanded: true, // Make the dropdown fill the available space
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
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF39cdaf)),
              ),
            ),
            // Add button
            TextButton(
              onPressed: () {
                _addMedicine(); // Add the medicine when this is pressed
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                "Add",
                style: TextStyle(color: Color(0xFF39cdaf)),
              ),
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
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF39cdaf), // Mint Green
              Color(0xFF0E4C92), // Navy Blue
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: _showDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF39cdaf), // Custom color
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Add Medicine",
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Medicine List:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _medicineList.isEmpty
                ? Text('No medicines added yet')
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _medicineList.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(_medicineList[index]),
                  onDismissed: (direction) {
                    _deleteMedicine(index); // Delete the medicine when swiped
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(
                      _medicineList[index],
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
