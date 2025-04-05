import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart' as wm;
import 'package:background_fetch/background_fetch.dart' as bf;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/map_screen.dart';
import 'services/background_task.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  wm.Workmanager().executeTask((task, inputData) async {
    await BackgroundTask.checkAndNotify();
    return Future.value(true);
  });
}

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 Inițializare notificări
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ Android → Workmanager
  if (Platform.isAndroid) {
    await wm.Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await wm.Workmanager().registerPeriodicTask(
      'bar-check-task',
      'checkProximityToBar',
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: wm.Constraints(
        networkType: wm.NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
    );
  }

  // 🍏 iOS → background_fetch
  if (Platform.isIOS) {
    bf.BackgroundFetch.configure(
      bf.BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: bf.NetworkType.ANY,
      ),
      (String taskId) async {
        print("[BackgroundFetch] Event received: $taskId");
        await BackgroundTask.checkAndNotify();
        bf.BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        // Timeout handler
        bf.BackgroundFetch.finish(taskId);
      },
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bar Feedback',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MapScreen(),
    );
  }
}
