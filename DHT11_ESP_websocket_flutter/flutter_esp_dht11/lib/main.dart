import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'temphumi.dart';

const String esp_url = 'ws://192.168.99.100:81';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'DHT11 eps-websocket-flutter',
      home: MyHomePage(title: 'Home control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoaded = false;
  String msg = '';
  TempHumi dht = TempHumi(0, 0);
  final channel = IOWebSocketChannel.connect(esp_url);
  @override
  void initState() {
    super.initState();

    channel.stream.listen(
      (message) {
        channel.sink.add('Flutter received $message');
        if (message == "connected") {
          print('Received from MCU: $message');
          setState(() {
            msg = message;
          });
        } else {
          print('Received from MCU: $message');
          Map<String, dynamic> json = jsonDecode(message);
          setState(() {
            dht = TempHumi.fromJson(json);
            isLoaded = true;
          });
        }
        //channel.sink.close(status.goingAway);
      },
      onDone: () {
        //if WebSocket is disconnected
        print("Web socket is closed");
        setState(() {
          msg = 'disconnected';
          isLoaded = false;
        });
      },
      onError: (error) {
        print(error.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: !isLoaded
            ? CircularProgressIndicator()
            : Text(
                '${dht.humi.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 60, color: Colors.red),
              ),
      ),
    );
  }
}

// {'temp':'36.000','humidity':'36.000%','heat':'36.000'}
