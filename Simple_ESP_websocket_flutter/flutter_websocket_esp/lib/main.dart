import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Simple eps-websocket-flutter',
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
  String msg = '';
  final channel = IOWebSocketChannel.connect('ws://192.168.99.100:81');
  @override
  void initState() {
    super.initState();

    channel.stream.listen(
      (message) {
        print('Received from MCU: $message');
        channel.sink.add('Flutter received $message');
        setState(() {
          msg = message;
        });
        // channel.sink.close(status.goingAway);
      },
      onDone: () {
        //if WebSocket is disconnected
        print("Web socket is closed");
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
        child: Text(
          msg,
          style: TextStyle(fontSize: 60, color: Colors.red),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          channel.sink.add("add");
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// {'temp':'36.000','humidity':'36.000%','heat':'36.000'}
