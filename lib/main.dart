import 'package:flutter/material.dart';
import 'start.dart'; // Import the start.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    // Delayed navigation to the Start screen after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StartScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26394A),
      body: Column(
        children: <Widget>[
          const Spacer(), // Pushes content to the bottom

          // Align to center the logo and text horizontally
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display the logo
                Image.asset(
                  'asset/image/logo.png',
                  width: 180, // Adjust the width as needed
                  height: 180, // Adjust the height as needed
                ),
                const SizedBox(height: 10),
                // Display the "PillCare" text with custom styling
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Pill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Care',
                        style: TextStyle(
                          color: Color(0xFF39cdaf),
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // Adds some space below the text and logo
        ],
      ),
    );
  }
}
