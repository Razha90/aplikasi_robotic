import 'dart:io';
import 'dart:math';

import 'package:aplikasi_robotic/help/bluetooth.dart';
import 'package:aplikasi_robotic/page/bluetooth_active.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // String _filePath = "";
  @override
  void initState() {
    super.initState();
  }

  // final List<DataPoint> _dataPoints = [
  //   DataPoint(100, 1),
  //   DataPoint(200, 2),
  //   DataPoint(300, 3),
  //   DataPoint(400, 4),
  //   DataPoint(500, 5),
  //   DataPoint(600, 6),
  //   DataPoint(700, 7),
  //   DataPoint(800, 8),
  //   DataPoint(900, 9),
  //   DataPoint(1000, 10),
  // ];

  // String getRandomFileName({int length = 10}) {
  //   const String chars =
  //       "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  //   Random random = Random();

  //   return List.generate(length, (index) => chars[random.nextInt(chars.length)])
  //       .join();
  // }

  // Future<void> exportExcel() async {
  //   var status = await Permission.storage.request();
  //   if (!status.isGranted) {
  //     print("Izin penyimpanan tidak diberikan");
  //     if (mounted) {
  //       CherryToast.warning(
  //         title: Text("Izin Penyiapanan dibutuhkan!",
  //             style:
  //                 GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 12)),
  //         action: Text(
  //           "Pastikan izin penyimpanan diaktifkan",
  //           style: GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 12),
  //         ),
  //       ).show(context);
  //     }
  //     return;
  //   }

  //   var excel = Excel.createExcel();
  //   Sheet sheetObject =
  //       excel['analisis-${DateTime.now().millisecondsSinceEpoch}'];
  //   sheetObject.appendRow([
  //     TextCellValue("Pulse"),
  //     TextCellValue("Speed"),
  //   ]);

  //   for (var row in _dataPoints) {
  //     sheetObject.appendRow([
  //       IntCellValue(row.pulse),
  //       DoubleCellValue(row.value),
  //     ]);
  //   }

  //   excel.delete('Sheet1');

  //   var fileBytes = excel.save();

  //   if (fileBytes == null) {
  //     print("Gagal menyimpan file");
  //     if (mounted) {
  //       CherryToast.error(
  //         title: Text("Gagal menyimpan file",
  //             style:
  //                 GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12)),
  //         action: Text(
  //           "Coba lagi, dan periksa izin penyimpanan",
  //           style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
  //         ),
  //       ).show(context);
  //     }
  //     return;
  //   }

  //   Directory directory = Directory("/storage/emulated/0/Download");
  //   if (!directory.existsSync()) {
  //     directory.createSync(recursive: true);
  //   }
  //   String filePath = "${directory.path}/output-analisis.xlsx";

  //   File file = File(filePath);
  //   await file.writeAsBytes(fileBytes);

  //   print("File disimpan di: $filePath");
  //   if (mounted) {
  //     CherryToast.success(
  //       animationType: AnimationType.fromTop,
  //       title: Text("File berhasil disimpan",
  //           style: GoogleFonts.poppins(color: Colors.green, fontSize: 12)),
  //       action: Text(
  //         "File disimpan di folder Download",
  //         style: GoogleFonts.poppins(color: Colors.green, fontSize: 12),
  //       ),
  //     ).show(context);
  //   }
  //   setState(() {
  //     _filePath = filePath;
  //   });
  // }

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
            // ElevatedButton(
            //     onPressed: () {
            //       exportExcel();
            //     },
            //     child: Text("Simpan Data Excel")),
            // if (_filePath.isNotEmpty)
            //   ElevatedButton(
            //     onPressed: () async {
            //       await OpenFilex.open(_filePath);
            //     },
            //     child: Text("Buka File Excel"),
            //   ),
          ],
        ));
  }
}
