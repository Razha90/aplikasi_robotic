// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_classic/flutter_blue_classic.dart';

// class BluetoothController extends ChangeNotifier {
//   final FlutterBlueClassic _bluetooth = FlutterBlueClassic();
//   BluetoothAdapterState _btState = BluetoothAdapterState.unknown;
//   StreamSubscription<BluetoothAdapterState>? _btSubscription;

//   BluetoothAdapterState get btState => _btState ;

//   BluetoothController() {
//     _startListening();
//   }

//   void _startListening() {
//     _btSubscription =
//         _bluetooth.adapterState.listen((BluetoothAdapterState state) {
//       _btState = state;
//       notifyListeners();
//     });
//   }

//   void turnOnBluetooth() {
//     _bluetooth.turnOn();
//   }

//   @override
//   void dispose() {
//     _btSubscription?.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class BluetoothController extends ChangeNotifier {
  final FlutterBlueClassic _bluetooth = FlutterBlueClassic();
  // BluetoothAdapterState _btState = BluetoothAdapterState.unknown;
  bool _btState = false;
  StreamSubscription<BluetoothAdapterState>? _btSubscription;
  bool _isScanning = false;

  final Set<BluetoothDevice> _scanResults = {};

  bool get btState => _btState;
  bool get isScanning => _isScanning;
  Set<BluetoothDevice> get scanResults => _scanResults;
  FlutterBlueClassic get bluetooth => _bluetooth;

  BluetoothController() {
    _initBluetoothState();
    _startListening();
    _listeningResults();
    _listeningScanning();
  }

  Future<void> _initBluetoothState() async {
    var check = await _bluetooth.adapterStateNow;
    bool checking = check == BluetoothAdapterState.on;
    if (_btState != checking) {
      _btState = checking;
      notifyListeners();
    }
  }

  void _startListening() {
    _btSubscription =
        _bluetooth.adapterState.listen((BluetoothAdapterState state) {
      debugPrint("Bluetooth State Event Diterima: $state");
      bool checking = state == BluetoothAdapterState.on;
      if (_btState != checking) {
        _btState = checking;
        notifyListeners();
      }
    });
  }

  void _listeningResults() {
    _bluetooth.scanResults.listen((results) {
      _scanResults.add(results); // ✅ Tambahkan satu per satu
      notifyListeners();
    });
  }

  void _listeningScanning() {
    _bluetooth.isScanning.listen((event) {
      _isScanning = event;
      notifyListeners();
    });
  }

  void reqBoundary() async {
    var check = await _bluetooth.bondedDevices;
    if (check!.isNotEmpty) {
      _scanResults.clear();
      _scanResults.addAll(check);
      notifyListeners();
    }
  }

  Future<BluetoothConnection?> connectDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection? connect = await _bluetooth.connect(device.address);
      return connect;
    } catch (e) {
      return null;
    }
  }

  void turnOnBluetooth() async {
    _bluetooth.turnOn();
    bool checking = await _bluetooth.isEnabled;
    if (_btState != checking) {
      _btState = checking;
      notifyListeners();
    }
  }

  int getRssi(BluetoothDevice device) {
    // return device.rssi;
    return 3;
  }

  // void scanning() async {
  //   if (_btState != BluetoothAdapterState.on) {
  //     await Future.delayed(Duration(seconds: 2)); // Beri waktu untuk menyala
  //   }
  //   bluetooth.startScan();
  // }

  Future<void> scanning() async {
    var check = await _bluetooth.isScanningNow;
    if (check) {
      _bluetooth.stopScan();
      _isScanning = false;
    } else {
      _scanResults.clear();
      _bluetooth.startScan();
      _isScanning = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _btSubscription?.cancel();
    super.dispose();
  }
}
