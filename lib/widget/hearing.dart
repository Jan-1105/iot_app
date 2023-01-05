import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'package:iot_app/model/spectrum.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

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
  bool _play_upper = false;
  bool _play_lower = false;
  bool _show_result = false;
  String? _current;
  List<dynamic>? _playlist;
  String _maxupper = '10000hz';
  String _maxlower = '10000hz';
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
    bool location = await Permission.locationWhenInUse.isGranted;
    if (!(bluetooth && bluetoothScan && bluetoothConnect && location)) {
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
    await Permission.locationWhenInUse.request();
  }

  _play() {
    setState(() {
      _playing = true;
    });
    _streamSubscription = eSenseManager.sensorEvents.listen((event) {
      if (event.gyro != null) {
        // if (event.gyro![2] > 2000) {
        //   up = true;
        // }
        if (event.gyro![2] < -2000) {
          //up = false;
          _next();
        }
      }
    });
    _playSound();
  }

  _next() {
    if (_playlist == upper) {
      _play_upper = false;
    } else {
      _play_lower = false;
      _cancel();
    }
  }

  _playSound() async {
    _show_result = true;
    setState(() {
      _playing = true;
    });
    _play_upper = true;
    _playlist = upper;
    for (int i = 0; i < upper.length && _play_upper; i++) {
      if (!_playing) {
        player.stop();
        _playlist = null;
        _current = null;
        return;
      }
      setState(() {
        _maxupper = upper[i].name;
        _current = upper[i].name;
      });
      String path = upper[i].getPath();
      Source asset = AssetSource(path);
      await player.pause();
      await player.setVolume(0.05);
      await player.setSource(asset);
      await player.resume();
      sleep(const Duration(seconds: 2));
    }
    _play_lower = true;
    _playlist = lower;
    for (int i = 0; i < lower.length && _play_lower; i++) {
      if (!_playing) {
        player.stop();
        _playlist = null;
        _current = null;
        return;
      }
      setState(() {
        _maxlower = lower[i].name;
        _current = lower[i].name;
      });
      String path = lower[i].getPath();
      Source asset = AssetSource(path);
      await player.pause();
      await player.setVolume(0.05);
      await player.setSource(asset);
      await player.resume();
      sleep(const Duration(seconds: 2));
    }

    _cancel();
  }

  _cancel() async {
    player.pause();
    player.stop();
    _streamSubscription.cancel();
    _play_upper = false;
    _play_lower = false;
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
            Text(
              _connected ? 'Gerät verbunden!' : 'Gerät nicht verbunden!',
              style: TextStyle(
                  color: _connected ? Colors.green : Colors.red, fontSize: 18),
            ),
            if (_connected) const Text('Bereit den Test zu starten'),
            if (!_connected)
              ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll<Color>(Colors.red)),
                onPressed: _connectToESense,
                child: const Text('Verbinden'),
              ),
            const SizedBox(height: 80),
            Text(
              _connected
                  ? (_playing && _current != null
                      ? 'Es läuft gerade: $_current'
                      : 'Button klicken um Ihr Hörspektrum zu testen.\n Wenn Sie nichts hören dann Nicken Sie.')
                  : 'Verbindung notwendig um den Test zu starten',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (_playing)
              const Text(
                  'Wenn Sie länger nichts hören dann Nicken Sie eindeutig.'),
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (_playing) {
                        return Colors.red;
                      }
                      return null; // Use the component's default.
                    },
                  ),
                ),
                onPressed: _connected ? (_playing ? _cancel : _play) : null,
                child: Text(_connected
                    ? (_playing ? 'Test abbrechen' : 'Test starten')
                    : 'Erst verbinden')),
            const SizedBox(height: 80),
            if (_show_result)
              Text(
                'Ihr Hörspektrum ist:\n $_maxlower - $_maxupper',
                style: const TextStyle(fontSize: 24, color: Colors.green),
                textAlign: TextAlign.center,
              ),
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
