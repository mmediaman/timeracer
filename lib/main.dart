import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() {
  runApp(const TimeRacerApp());
}

class TimeRacerApp extends StatelessWidget {
  const TimeRacerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeRacer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TimeRacerHome(),
    );
  }
}

class TimeRacerHome extends StatefulWidget {
  const TimeRacerHome({Key? key}) : super(key: key);

  @override
  _TimeRacerHomeState createState() => _TimeRacerHomeState();
}

class _TimeRacerHomeState extends State<TimeRacerHome> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int wakeUpInterval = 5;
  String selectedAlertSound = 'Default';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startBackgroundTimer();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'time_racer_channel',
      'TimeRacer Notifications',
      channelDescription: 'Notifications for TimeRacer app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'We are moving',
      'You are traveling at or above 10mph',
      platformChannelSpecifics,
    );
  }

  void _startBackgroundTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(minutes: wakeUpInterval), (Timer t) async {
      Position position = await _getCurrentPosition();
      double speedInMph = (position.speed * 2.23694);

      if (speedInMph >= 10) {
        _showNotification();
        _showPopup();
      }
    });
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _showPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('We are moving'),
          content: const Text('You are traveling at or above 10mph'),
          actions: [
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Snooze'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeRacer Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Wake Up Interval (minutes):'),
                DropdownButton<int>(
                  value: wakeUpInterval,
                  items: [5, 10, 15, 20, 30].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      wakeUpInterval = newValue ?? 5;
                      _startBackgroundTimer();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notification Alert Sound:'),
                DropdownButton<String>(
                  value: selectedAlertSound,
                  items: ['Default', 'Chime', 'Beep'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAlertSound = newValue ?? 'Default';
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
