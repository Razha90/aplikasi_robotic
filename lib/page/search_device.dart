// import 'dart:async';
// import 'package:aplikasi_robotic/help/bluetooth.dart';
// import 'package:bluetooth_classic/models/device.dart';
// import 'package:flutter/material.dart';

// class SearchDevice extends StatefulWidget {
//   const SearchDevice({super.key});

//   @override
//   State<SearchDevice> createState() => _SearchDeviceState();
// }

// class _SearchDeviceState extends State<SearchDevice> {
//   late BluetoothController _bluetoothController;

//   @override
//   void initState() {
//     super.initState();
//     _bluetoothController = BluetoothController();
//     _bluetoothController.turnOnBluetooth();
//   }

//   @override
//   void dispose() {
//     _bluetoothController.dispose();
//     super.dispose();
//   }

//   void _check() async {
//     // print(await _bluetoothController.isScanning());
//   }

//   void update() {
//     // _bluetoothController.updateState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           ElevatedButton(
//             onPressed: _check,
//             child: const Text('Check'),
//           ),
//           ElevatedButton(
//             onPressed: update,
//             child: const Text('Update'),
//           ),
//           Expanded(
//             child: ListView.builder(
//                 itemCount: _bluetoothController.scanResults.length,
//                 itemBuilder: (context, index) {
//                   final device = _bluetoothController.scanResults[index];
//                   return SizedBox(
//                     height: 50,
//                     child: ListTile(
//                       title: Text(device.address),
//                       subtitle: Text(device.name!),
//                     ),
//                   );
//                 }),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BluetoothDevice {
//   final String name;
//   final String address;

//   BluetoothDevice(this.name, this.address);
// }
