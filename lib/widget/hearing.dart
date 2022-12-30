import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'package:iot_app/model/spectrum.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

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
  String? _current;
  final AudioPlayer player = AudioPlayer();
  late StreamSubscription _streamSubscription;
  bool up = false;

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

  _play() async {
    setState(() {
      _playing = true;
    });
    _streamSubscription = eSenseManager.sensorEvents.listen((event) {
      if (event.gyro != null) {
        if (event.gyro![0] > 0.5) {
          up = true;
        }
        if (up && event.gyro![0] < -0.5) {
          _cancel();
        }
      }
    });
    _playSound(upper, 0);
  }

  _playSound(List sounds, int i) async {
    if (!_playing) {
      player.stop();
      return;
    }
    ;
    setState(() {
      _current = sounds[i].name;
    });
    await player.setSource(AssetSource(sounds[i].getPath()));
    await player.resume();
    sleep(const Duration(seconds: 2));
    if (sounds.length > i + 1) {
      _playSound(sounds, i + 1);
    } else {
      if (sounds == upper) {
        _playSound(lower, 0);
      } else {
        await player.pause();
        setState(() {
          _playing = false;
        });
      }
    }
  }

  _cancel() {
    setState(() {
      _playing = false;
    });
    player.stop();
    _streamSubscription.cancel();
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
              _playing && _current != null
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
