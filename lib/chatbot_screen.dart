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
  FocusNode _focusNode = FocusNode(); // FocusNode to manage cursor focus

  // Your OpenAI API key
  final String _apiKey = 'YOUR_OPENAI_API_KEY';

  @override
  void initState() {
    super.initState();
    // Automatically request focus on the text field when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Clean up the FocusNode
    _controller.dispose();
    super.dispose();
  }

  // Function to send message to OpenAI
  Future<void> _sendMessageToOpenAI(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'content': message});
    });

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': _messages, // Send the whole conversation history
        'max_tokens': 100,
        'temperature': 0.7, // Control randomness, adjust for accuracy
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final aiResponse = data['choices'][0]['message']['content'];

      setState(() {
        _messages.add({'role': 'assistant', 'content': aiResponse});
      });
    } else {
      print('Failed to connect to OpenAI API: ${response.statusCode}');
    }
  }

  // Function to handle message send on Enter key or Send button
  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      _controller.clear(); // Clear input field
      _sendMessageToOpenAI(message); // Send message to OpenAI
      _focusNode
          .requestFocus(); // Keep the cursor in the text field after sending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with Health Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                        : Alignment
                            .centerLeft, // AI message on left, user on right
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user'
                            ? Colors.blueAccent
                            : Colors
                                .grey[300], // Different color for AI messages
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
                    focusNode: _focusNode, // Keep focus in the input field
                    decoration: InputDecoration(
                      hintText: 'Type a message',
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
