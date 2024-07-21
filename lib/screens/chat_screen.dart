import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // making variable that keep the instance of gemini
  final Gemini gemini = Gemini.instance;
  // List of chat messeage
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser genminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Gemini Chatbot"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      // spread oprater, take the messages list and take all that elements from that list and add the to this(messages) new list
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      gemini.streamGenerateContent(question).listen((event) {
        // respone
        ChatMessage? lastMessage = messages.firstOrNull;
        // check if the last message is from gemini or user
        if (lastMessage != null && lastMessage.user == genminiUser) {
          // apppend new event text that get to the message
          lastMessage = messages.removeAt(0);
          String newResponse = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          lastMessage.text += newResponse;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage newMessage = ChatMessage(
            user: genminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [newMessage, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }
}
