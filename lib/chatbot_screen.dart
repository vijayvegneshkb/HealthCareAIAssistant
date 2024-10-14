import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  List<String> _messages = [];
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Chat with Health Assistant',
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
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_messages[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    setState(() {
                      _messages.add(_controller.text); // Add message to list
                      _controller.clear(); // Clear the input field
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
