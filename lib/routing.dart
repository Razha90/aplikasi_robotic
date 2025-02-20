import 'package:aplikasi_robotic/page/connect_device.dart';
import 'package:aplikasi_robotic/page/my_home_page.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => MyHomePage());
    case '/connecting':
      return MaterialPageRoute(
          builder: (_) => ConnectDevice(
                connection: settings.arguments as BluetoothConnection,
              ));

    default:
      return null;
  }
}
