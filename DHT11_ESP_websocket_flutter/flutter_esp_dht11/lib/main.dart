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
          // {'tempC':'36.00','humi':'36.00'}
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
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text('Nhiệt độ: ',
                            style: TextStyle(fontSize: 50, color: Colors.blue)),
                        Text(
                          '${dht.tempC.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 50, color: Colors.blue),
                        ),
                        Text(
                          '°C',
                          style: TextStyle(fontSize: 30, color: Colors.blue),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text('Độ ẩm: ',
                            style: TextStyle(fontSize: 50, color: Colors.blue)),
                        Text(
                          '${dht.humi.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 50, color: Colors.blue),
                        ),
                        Text(
                          ' %',
                          style: TextStyle(fontSize: 20, color: Colors.blue),
                        )
                      ],
                    )
                  ],
                )),
    );
  }
}
