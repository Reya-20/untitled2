import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Light gray background
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // The rounded rectangle container at the top with no margin
              Container(
                height: 450, // Adjust height based on your design
                decoration: const BoxDecoration(
                  color: Color(0xFF26394A), // Dark blue color
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              // Display the logo above the container
              Positioned(
                top: 40, // Adjust the position as needed
                child: Image.asset(
                  'asset/image/start_logo_above.png', // Path to the logo image
                  width: 350, // Adjust the width based on your design
                  height: 350, // Adjust the height based on your design
                ),
              ),
            ],
          ),
          // Add margin between the container and the welcome text
          const SizedBox(height: 50), // Adjust the height of the margin as needed

          // Welcome text with custom styling
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome to ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Pill',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Care',
                  style: TextStyle(
                    color: Color(0xFF39cdaf), // Custom green color
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30), // Space between text and button
          // Create Account Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26394A), // Dark blue color
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Rounded corners
              ),
            ),
            child: const Text(
              'Start Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20), // Space between button and login link
          // Already have an account? Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateAccountScreen()),
                  );
                },
                child: const Text(
                  "Register",
                  style: TextStyle(
                    color: Color(0xFF39cdaf), // Custom green color
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
