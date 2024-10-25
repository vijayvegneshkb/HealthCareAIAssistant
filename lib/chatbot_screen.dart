import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:collection';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  List<Map<String, dynamic>> _messages = []; // Stores role, content, medicines, and note
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  final String _apiUrl = 'http://localhost:8000/recommendation/';

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessageToBackend(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'content': message});
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('data :$data');
        var aiResponse = data['response']['summary'] ?? 'No summary available.';
        bool hasSummary = data['response']['summary'] != null;
        print('has_summary: $hasSummary');

        if ((aiResponse is String) && hasSummary) {
          aiResponse = aiResponse.replaceAll(RegExp(r'```json|```'), '').trim();
          aiResponse = json.decode(aiResponse);

          final List medicines = aiResponse['medicines'] ?? [];
          final String note = aiResponse['disclaimer'] ?? '';

          if(medicines.isEmpty){
            setState(() {
              _messages.add({'role': 'assistant', 'content': aiResponse['message']});
            });
          }else{
            setState(() {
              _messages.add({
                'role': 'assistant',
                'content': aiResponse['message'],
                'medicines': medicines,
                'note': note,
              });
            });
          }   
        }
        else{
          var aiResponse = data['response'] ?? 'No response available.';
          setState(() {
            _messages.add({'role': 'assistant', 'content': aiResponse['message']});
          });
        }
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: Unable to connect to backend.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: Failed to send message.'});
      });
    }
  }

  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      _controller.clear();
      _sendMessageToBackend(message);
      _focusNode.requestFocus();
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

                if (message['role'] == 'assistant') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message['content']!,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      // Display medicines if available
                      if (message['medicines'] != null && message['medicines'].isNotEmpty)
                        ...message['medicines'].map<Widget>((medicine) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(8),
                              title: Text(medicine['name']),
                              subtitle: Text("Price: \$${medicine['price']}"),
                              leading: Image.network(
                                medicine['image']!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      // Display note if available
                      if (message['note'] != null && message['note'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            message['note']!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                    ],
                  );
                } else {
                  return ListTile(
                    title: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['content']!,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
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
                      _handleSendMessage();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
