import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personal Health Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome to Your Personal Health Assistant!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Image.asset(
                'assets/icons/health_icon.png', // Make sure to add a suitable icon
                width: 400,
                height: 200,
              ),
              SizedBox(height: 20),
              // Chat with Assistant Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/chatbot'); // Navigate to chatbot screen
                  },
                  child: Text('Chat with Assistant'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 16), // Increase vertical padding
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Medical Products Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context,
                        '/medicalProducts'); // Navigate to medical products screen
                  },
                  child: Text('Medical Products'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 16), // Increase vertical padding
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Appointments Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    // Add navigation for appointments screen
                    // Navigator.pushNamed(context, '/appointments');
                  },
                  child: Text('Appointments'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 16), // Increase vertical padding
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
