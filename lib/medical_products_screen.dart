import 'package:flutter/material.dart';

class MedicalProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Medical Products',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back, // Back arrow icon
              color: Colors.white, // Change the color here
              size: 24, // Change the size (weight) here
            ),
            onPressed: () {
              Navigator.pop(context); // Go back to the previous screen
            },
          ),
          backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Two items per row
            childAspectRatio: 0.65, // Aspect ratio of each grid item
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: 6, // Change this based on your product count
          itemBuilder: (context, index) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/sugar_test.png', // Placeholder image, update with actual image
                    width: 600,
                    height: 300,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sugar Test Kit', // Sample product name
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                      'The Sugar Metabolism Kit provides a hands-on introduction to biochemistry and the nutritional impact of sugars.'),
                  SizedBox(height: 10),
                  // Quantity and Add to Cart buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Quantity Button
                      // ElevatedButton(
                      //   onPressed: () {
                      //     // Add functionality to increase quantity
                      //   },
                      //   child: Text('Quantity'),
                      // ),
                      // Add to Cart Button
                      ElevatedButton(
                        onPressed: () {
                          // Add functionality to add item to cart
                        },
                        child: Text('Add to Cart'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
