import 'dart:io';

import 'package:abbot/screen/navigation_bar/main_nav.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permission (Android only)
  if (Platform.isAndroid) {
    await Permission.manageExternalStorage.request();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Trade Exit App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainNav(),
    );
  }
}
