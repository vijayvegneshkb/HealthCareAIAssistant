import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHoveredChat = false;
  bool isHoveredMedical = false;
  bool isHoveredAppointments = false;
  bool isHoveredMedications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            'Personal Health Assistant',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Healthcare Banner Section with Doctor Photo
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  color: Colors.blue[900],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 20),
                      Text(
                        'Healthcare',
                        style: TextStyle(
                          fontSize: 100,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 100),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20),
                          Icon(Icons.no_meals,
                              color: Colors.lightBlueAccent, size: 20),
                          SizedBox(width: 5),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/icons/doctor.png', // Replace with the actual doctor image path
                    height: 230, // Adjusted size similar to the UI image
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Cards Section - Horizontally aligned with equal width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHoverableCard(
                    context,
                    Icons.chat,
                    'Chat with Assistant',
                    Colors.yellow[600]!,
                    '/chatbot',
                    isHoveredChat,
                    (hovering) {
                      setState(() {
                        isHoveredChat = hovering;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  _buildHoverableCard(
                    context,
                    Icons.local_hospital,
                    'Medical Products',
                    Colors.green[300]!,
                    '/medicalProducts',
                    isHoveredMedical,
                    (hovering) {
                      setState(() {
                        isHoveredMedical = hovering;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  _buildHoverableCard(
                    context,
                    Icons.local_pharmacy,
                    'Appointments',
                    Colors.pink[200]!,
                    '/medicines',
                    isHoveredAppointments,
                    (hovering) {
                      setState(() {
                        isHoveredAppointments = hovering;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  _buildHoverableCard(
                    context,
                    Icons.science,
                    'Personal Medications',
                    Colors.blue[200]!,
                    '/labTests',
                    isHoveredMedications,
                    (hovering) {
                      setState(() {
                        isHoveredMedications = hovering;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build hoverable cards
  // Helper function to build hoverable cards
  Widget _buildHoverableCard(
    BuildContext context,
    IconData icon,
    String label,
    Color bgColor,
    String route,
    bool isHovered,
    ValueChanged<bool> onHover,
  ) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Change cursor when hovering
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(16),
            height: 180, // Adjust height for uniformity
            decoration: BoxDecoration(
              color: isHovered ? bgColor.withOpacity(0.8) : bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: bgColor.withOpacity(0.4),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 50),
                SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
