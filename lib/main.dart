import 'package:flutter/material.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'medical_products_screen.dart';
import 'checkout_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Health Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Default screen
      routes: {
        '/chatbot': (context) => ChatbotScreen(),
        '/medicalProducts': (context) => MedicalProductsScreen(),
        '/checkout': (context) => CheckoutScreen(), // New route for checkout
      },
    );
  }
}
