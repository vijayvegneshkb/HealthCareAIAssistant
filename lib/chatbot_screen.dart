import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  List<Map<String, String>> _messages = []; // Stores role & content
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode(); // Manage cursor focus

  final String _apiUrl = 'http://localhost:8000/recommendation/';  // FastAPI server URL

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Function to send message to the FastAPI backend
  Future<void> _sendMessageToBackend(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'content': message});
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message, // Sending user message to the backend
        }),
      );

      // Log the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract the assistant's response properly
        final aiResponse = data['response']['summary'] ?? 'No summary available.';

        // Check if aiResponse is a String
        if (aiResponse is String) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': aiResponse});
          });
        } else {
          print('Unexpected response type: ${aiResponse.runtimeType}');
          setState(() {
            _messages.add({'role': 'assistant', 'content': 'Error: Invalid response from assistant.'});
          });
        }
      } else {
        print('Failed to connect to backend: ${response.statusCode}');
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: Unable to connect to backend.'});
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: Failed to send message.'});
      });
    }
  }


  // Handle message send on Enter key or Send button
  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      _controller.clear(); // Clear input field
      _sendMessageToBackend(message); // Send message to FastAPI backend
      _focusNode.requestFocus(); // Keep the cursor in the text field
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Health Assistant'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Align(
                    alignment: message['role'] == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft, // AI message on left, user on right
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user'
                            ? Colors.blueAccent
                            : Colors.grey[300], // Different color for AI messages
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message['content']!,
                        style: TextStyle(
                          color: message['role'] == 'user'
                              ? Colors.white
                              : Colors.black, // Text color based on sender
                        ),
                      ),
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
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Describe your symptoms...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _handleSendMessage(); // Send message on pressing Enter
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _handleSendMessage, // Send message on button press
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
