import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SenderPage());
  }
}

class SenderPage extends StatefulWidget {
  @override
  _SenderPageState createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {

  final token = TextEditingController();
  final chat = TextEditingController();
  final msg = TextEditingController();

  bool running = false;

  Future send() async {

    running = true;

    while(running){

      await http.post(
        Uri.parse(
          "https://api.telegram.org/bot${token.text}/sendMessage"
        ),
        body: {
          "chat_id": chat.text,
          "text": msg.text
        }
      );

      await Future.delayed(Duration(seconds:1));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Telegram Sender")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: token,
              decoration: InputDecoration(labelText: "Bot Token"),
            ),

            TextField(
              controller: chat,
              decoration: InputDecoration(labelText: "Chat ID"),
            ),

            TextField(
              controller: msg,
              decoration: InputDecoration(labelText: "Message"),
            ),

            ElevatedButton(
              onPressed: send,
              child: Text("Start"),
            )

          ],
        ),
      ),
    );
  }
}