import 'package:aplikasi_robotic/help/bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothController blueController =
        Provider.of<BluetoothController>(context, listen: true);
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            blueController.scanning();
          },
          child: blueController.isScanning
              ? Icon(
                  Icons.stop,
                  color: Colors.redAccent,
                )
              : Icon(Icons.search),
        ),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("Test Speed Prototype"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(blueController.btState
                          ? "Bluetooth On"
                          : "Bluetooth Off"),
                    ],
                  ),
                  Switch(
                    value: blueController.btState,
                    onChanged: (value) async {
                      if (value) {
                        blueController.turnOnBluetooth();
                      }
                    },
                    activeTrackColor: Colors.lightBlue.shade100,
                    activeColor: Colors.lightBlueAccent,
                  ),
                ],
              ),
            ),
            Divider(),
            Consumer<BluetoothController>(
              builder: (context, controller, child) {
                if (controller.btState) {
                  return Column(
                    children: [
                      if (controller.scanResults.isNotEmpty)
                        SizedBox(
                          height: 500,
                          child: ListView.builder(
                              itemCount: controller.scanResults.length,
                              itemBuilder: (context, index) {
                                BluetoothDevice result =
                                    controller.scanResults.elementAt(index);

                                return SizedBox(
                                  height: 70,
                                  child: ListTile(
                                    title: Text(result.name ?? ""),
                                    subtitle: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text("${result.rssi.toString()}dBm"),
                                        ElevatedButton(
                                            onPressed: () async {
                                              // controller.connectDevice(result);
                                              BluetoothConnection? connect =
                                                  await controller
                                                      .connectDevice(result);
                                              if (connect != null &&
                                                  connect.isConnected) {
                                                if (context.mounted) {
                                                  Navigator.pushNamed(
                                                      context, '/connecting',
                                                      arguments: connect);
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  QuickAlert.show(
                                                      context: context,
                                                      type:
                                                          QuickAlertType.error,
                                                      title: "Gagal Terhubung",
                                                      text:
                                                          "Gagal terhubung ke perangkat ${result.name} silahkan coba lagi");
                                                }
                                              }
                                            },
                                            child: Text("Connect")),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                        ),
                    ],
                  );
                } else {
                  return Center(
                    child: SizedBox(
                      height: 200,
                      child: Text("Bluetooth is off"),
                    ),
                  );
                }
              },
            ),
          ],
        ));
  }
}
