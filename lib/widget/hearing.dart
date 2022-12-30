import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

import '../model/sound.dart';

class HearingPage extends StatefulWidget {
  const HearingPage({super.key, required this.title});

  final String title;

  @override
  State<HearingPage> createState() => _HearingPageState();
}

class _HearingPageState extends State<HearingPage> {
  ESenseManager eSenseManager = ESenseManager('eSense-0678');
  bool _connected = false;
  bool _playing = false;
  final Sound _current = Sound('Test', 'assets/sounds/test.mp3');
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _connectToESense();
  }

  void _connectToESense() async {
    bool bluetooth = await Permission.bluetooth.isGranted;
    bool bluetoothScan = await Permission.bluetoothScan.isGranted;
    bool bluetoothConnect = await Permission.bluetoothConnect.isGranted;
    if (!(bluetooth && bluetoothScan && bluetoothConnect)) {
      await _requestPermission();
    }
    await eSenseManager.disconnect();
    await eSenseManager.connect();

    eSenseManager.connectionEvents.listen((event) {
      setState(() {
        switch (event.type) {
          case ConnectionType.connected:
            _connected = true;
            break;
          case ConnectionType.unknown:
          case ConnectionType.disconnected:
          case ConnectionType.device_found:
          case ConnectionType.device_not_found:
          default:
            _connected = false;
            break;
        }
      });
    });
  }

  _requestPermission() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  _play() {
    setState(() {
      _playing = true;
    });
  }

  _cancel() {
    setState(() {
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_connected ? 'Gerät verbunden!' : 'Gerät nicht verbunden!'),
            if (!_connected)
              ElevatedButton(
                  onPressed: _connectToESense, child: const Text('Verbinden')),
            const SizedBox(height: 80),
            Text(
              _playing
                  ? 'Es läuft gerade: $_current'
                  : 'Drücken Sie den Button um Ihr Hörspektrum zu testen',
            ),
            if (_playing)
              const Text('Wenn Sie länger nichts hören dann Nicken Sie.'),
            ElevatedButton(
                onPressed: _playing ? _cancel : _play,
                child: Text(_playing ? 'Test abbrechen' : 'Test starten'))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    eSenseManager.disconnect();
    super.dispose();
  }
}
