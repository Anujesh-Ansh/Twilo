import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];


  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser twiloUser = ChatUser(id: "1", firstName: "Twilo");



  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Twilo'),
      ),
      body: _buildUI(),
    );
  }
  
  Widget _buildUI(){
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: _sendMediaMessage,
          icon: const Icon(Icons.image,),
        )
      ]),
      currentUser: currentUser, 
      onSend: _sendMessage, 
      messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage){
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try{
      String question = chatMessage.text;

      List<Uint8List>? images;

      if(chatMessage.medias?.isNotEmpty ?? false){
        images = [File(chatMessage.medias!.first.url).readAsBytesSync();]
      }


      gemini.streamGenerateContent(question, images:images,).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if(lastMessage != null && lastMessage.user.id == twiloUser.id){
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold("",(previous, current) => "$previous ${current.text}") ?? "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        }
        else{
          String response = event.content?.parts?.fold("",(previous, current) => "$previous ${current.text}") ?? "";
          ChatMessage message = ChatMessage(user: twiloUser, createdAt: DateTime.now(), text: response );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    }catch(e){
      print(e);
    }
    
  }


  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image != null){
      ChatMessage message = ChatMessage(user: currentUser, createdAt: DateTime.now(), text:"Describe this image", medias: [
        ChatMedia(url: image.path, fileName: "", type: MediaType.image)
      ]);

      _sendMessage(message);
    }
  }
}

