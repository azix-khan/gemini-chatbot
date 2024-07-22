import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

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
  // for typeing loading
  final List<ChatUser> _typingUsers = <ChatUser>[];

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
      body: buildUI(),
    );
  }

  Widget buildUI() {
    return DashChat(
      typingUsers: _typingUsers,
      scrollToBottomOptions: const ScrollToBottomOptions(),
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            onPressed: sendMediaMessage,
            icon: const Icon(
              Icons.image,
            ),
          ),
        ],
      ),
      currentUser: currentUser,
      onSend: sendMessage,
      messages: messages,
    );
  }

  // for message

  void sendMessage(ChatMessage chatMessage) {
    setState(() {
      // spread oprater, take the messages list and take all that elements from that list and add the to this(messages) new list
      messages = [chatMessage, ...messages];
      // Displaying Typing Indicator
      _typingUsers.add(genminiUser);
    });
    // Handling sending message to Gemini API
    try {
      String question = chatMessage.text;
      // Sending Image to Gemini API
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
        print('Image path: ${chatMessage.medias!.first.url}');
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
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
            // removing Typing Indicator after respone
            _typingUsers.remove(genminiUser);
          });
        }
      });
    } catch (error) {
      print("Error occurred: $error");
    }
  }

  // for image
  Future<void> sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    // constructing chat message
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          ),
        ],
      );
      sendMessage(chatMessage);
    }
  }
}
