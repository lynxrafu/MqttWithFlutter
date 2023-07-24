import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Message App',
      home: MqttMessageScreen(),
    );
  }
}

class MqttMessageScreen extends StatefulWidget {
  @override
  _MqttMessageScreenState createState() => _MqttMessageScreenState();
}

class _MqttMessageScreenState extends State<MqttMessageScreen> {
  List<String> messages = [];
  final client = MqttServerClient('ws://iothook.com/mqtt', 'mqttx_7cdfc93b');

  @override
  void initState() {
    super.initState();
    _initMqtt();
  }

  Future<void> _initMqtt() async {
    // MQTT initialization and connection code
    client.useWebSocket = true;
    client.port = 8083;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 2000;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;
    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    print('Mosquitto client connecting....');
    client.connectionMessage = connMess;
    try {
      await client.connect("publicmqttbroker", "publicmqttbroker");
    } on NoConnectionException catch (e) {
      print('client exception - $e');
      client.disconnect();
    }
    print(
        "ausasoodhashdashdaosdahodaodadodsaeyooooooooooooooooooooooooooooooo${client.connectionStatus!.state}");

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Mosquitto client connected');
    } else {
      print(
          'ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
    // Subscribe to the topic
    const topic = 'testtopic/#';
    client.subscribe(topic, MqttQos.atMostOnce);

    // Listen for incoming messages
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        messages.add(pt);
      });
    });
  }

  void _sendMessage(String message) {
    // Publish the message
    const pubTopic = 'testtopic/1';
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
    }
  }

  void _onConnected() {
    print('OnConnected client callback - Client connection was successful');
  }

  void _pong() {
    print('Ping response client callback invoked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Message App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageDisplayWidget(messages: messages),
          ),
          MessageInputWidget(onSendMessage: _sendMessage),
        ],
      ),
    );
  }
}

class MessageDisplayWidget extends StatelessWidget {
  final List<String> messages;

  MessageDisplayWidget({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(messages[index]),
        );
      },
    );
  }
}

class MessageInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;

  MessageInputWidget({required this.onSendMessage});

  @override
  _MessageInputWidgetState createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Enter your message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              String message = _messageController.text;
              if (message.isNotEmpty) {
                widget.onSendMessage(message);
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
