import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/home_screen.dart';
import 'src/theme.dart';
import 'src/trip_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final controller = TripController()..load();
  runApp(TaxiMathApp(controller: controller));
}

class TaxiMathApp extends StatelessWidget {
  const TaxiMathApp({super.key, required this.controller});

  final TripController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mzansi Taxi Math',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(controller: controller),
    );
  }
}
