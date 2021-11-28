import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

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
      title: 'Stepper eps-websocket-flutter',
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
  double pos = 0;
  double speed = 10;
  final channel = IOWebSocketChannel.connect(esp_url);
  @override
  void initState() {
    super.initState();

    channel.stream.listen(
      (message) {
        if (message == "connected") {
          print('Received from MCU: $message');
          setState(() {
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
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ' Position (r)',
                          style: TextStyle(fontSize: 20),
                        ),
                        Slider(
                          min: -10,
                          max: 10,
                          value: pos,
                          divisions: 20,
                          label: '${pos.round()}',
                          onChanged: (value) {
                            setState(() {
                              pos = value;
                            });
                          },
                        ),
                        Padding(padding: EdgeInsets.all(8)),
                        Text(' Speed (rpm)', style: TextStyle(fontSize: 20)),
                        Slider(
                          activeColor: Colors.orange,
                          min: 0,
                          max: 240,
                          value: speed,
                          divisions: 24,
                          label: '${speed.round()}',
                          onChanged: (value) {
                            setState(() {
                              speed = value;
                            });
                          },
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        String s =
                            '{"speed": ${speed.round()}, "position": ${pos.round()}}';
                        channel.sink.add(s);
                        print(s);
                      },
                      child: Text('Move'),
                    )
                  ],
                )),
    );
  }
}
