import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _address = '';
  String _creditCardNumber = '';
  int _orderNumber = 0;

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Generate a mock order number
      setState(() {
        _orderNumber = DateTime.now().millisecondsSinceEpoch;
      });

      // Navigate to order confirmation page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            name: _name,
            address: _address,
            creditCardNumber: _creditCardNumber,
            orderNumber: _orderNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicine = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row to display the medicine details and image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image aligned on the left
                Image.network(
                  medicine['image']!,
                  width: 100, // Set the width to make the image smaller
                  height: 100,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 16), // Space between image and text
                // Text content on the right of the image
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are buying: ${medicine['name']}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text('Price: \$${medicine['price']}'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Form to enter details
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _name = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Shipping Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _address = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Credit Card Number'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length != 16) {
                        return 'Please enter a valid 16-digit credit card number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _creditCardNumber = value!;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitOrder,
                    child: Text('Submit Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final String name;
  final String address;
  final String creditCardNumber;
  final int orderNumber;

  OrderConfirmationScreen({
    required this.name,
    required this.address,
    required this.creditCardNumber,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Confirmation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Thank you for your order, $name!', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Order Number: $orderNumber'),
            SizedBox(height: 10),
            Text('Shipping to: $address'),
            SizedBox(height: 10),
            Text('Payment made with card ending in: ${creditCardNumber.substring(12)}'),  // Display last 4 digits
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
