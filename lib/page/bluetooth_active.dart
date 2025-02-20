import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:aplikasi_robotic/help/line_chart.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BluetoothActive extends StatefulWidget {
  const BluetoothActive({super.key});

  @override
  State<BluetoothActive> createState() => _BluetoothActiveState();
}

class _BluetoothActiveState extends State<BluetoothActive> {
  final bluetoothClassicPlugin = BluetoothClassic();
  bool _scanning = false;
  List<Device> discoveredDevices = [];
  final Uint8List _data = Uint8List(0);
  int _deviceStatus = Device.disconnected;

  late StreamSubscription _dataReceived;
  late StreamSubscription _deviceDiscovered;
  late StreamSubscription _deviceStatusChanged;

  final List<DataPoint> _dataPoints = [];

  final TooltipBehavior _tooltipBehavior = TooltipBehavior();

  @override
  void initState() {
    super.initState();
    _dataReceived =
        bluetoothClassicPlugin.onDeviceDataReceived().listen((event) {
      print(event);
      setState(() {
        // _data = Uint8List.fromList([..._data, ...event]);
        // _dataPoints.add(DataPoint(
        //   value: event[0].toDouble(),
        //   timestamp: DateTime.now(),
        // ));
      });
    });
    _deviceDiscovered = bluetoothClassicPlugin.onDeviceDiscovered().listen(
      (event) {
        setState(() {
          discoveredDevices = [...discoveredDevices, event];
        });
      },
    );
    _deviceStatusChanged =
        bluetoothClassicPlugin.onDeviceStatusChanged().listen((event) {
      setState(() {
        _deviceStatus = event;
      });
    });
  }

  @override
  void dispose() {
    _dataReceived.cancel();
    _deviceDiscovered.cancel();
    _deviceStatusChanged.cancel();
    super.dispose();
  }

  void isScanning() async {
    if (_scanning) {
      await bluetoothClassicPlugin.stopScan();
      setState(() {
        _scanning = false;
      });
    } else {
      await bluetoothClassicPlugin.startScan();

      setState(() {
        _scanning = true;
      });
    }
  }

  Future<void> _getDevices() async {
    var res = await bluetoothClassicPlugin.getPairedDevices();
    for (var i = 0; i < res.length; i++) {
      print(res[i].name);
    }
  }

  void connectDevice() async {
    const String sppUUID = "00001101-0000-1000-8000-00805F9B34FB";

    var res = await bluetoothClassicPlugin.getPairedDevices();
    for (var i = 0; i < res.length; i++) {
      if (res[i].name == 'ESP32_Device') {
        await bluetoothClassicPlugin.connect(res[i].address, sppUUID);
      }
    }
  }

  void resultScan() {
    print(discoveredDevices.length);
  }

  void startScan() async {
    await bluetoothClassicPlugin.startScan();
  }

  void stopScan() async {
    await bluetoothClassicPlugin.stopScan();
  }

  void _chcekDevice() {
    print(_deviceStatus);
  }

  void sendData() {
    bluetoothClassicPlugin.write("cantik");
  }

  void readData() {
    print(_data);
  }

  void connectedDevice() async {
    const String sppUUID = "00001101-0000-1000-8000-00805F9B34FB";
    try {
      var res = await bluetoothClassicPlugin.getPairedDevices();
      if (res.isEmpty) {
        if (mounted) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            title: "Perangkat Tidak Ditemukan",
            text:
                "Perangkat dengan nama 'ESP32_Device' tidak ditemukan, silahkan pergi ke pengaturan bluetooth",
          );
        }
        return;
      }

      for (var i = 0; i < res.length; i++) {
        if (res[i].name == 'ESP32_Device') {
          try {
            await bluetoothClassicPlugin.connect(res[i].address, sppUUID);
            if (mounted) {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: "Perangkat Terhubung",
              );
            }
          } catch (e) {
            if (mounted) {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: "Gagal Terhubung",
                text: "Terjadi kesalahan saat terhubung ke perangkat",
              );
            }
            return;
          }
          return;
        }
      }

      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: "Perangkat Tidak Ditemukan",
          text:
              "Pastikan perangkat ESP32 sudah terpasang dan terhubung dengan perangkat ini",
        );
      }
    } catch (e) {
      // Menangani error pada pemanggilan getPairedDevices()
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: "Error",
          text: "Terjadi kesalahan saat mencari perangkat, silahkan coba lagi",
        );
      }
    }
  }

  void addDataPoint(List<DataPoint> dataPoints) {
    Random random = Random();

    int pulse = dataPoints.isEmpty ? 1 : dataPoints.last.pulse + 1;
    double value = random.nextDouble() * 255;

    setState(() {
      dataPoints.add(DataPoint(value, pulse));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                ),
                Icon(
                  Icons.bluetooth,
                  size: 100,
                  color: Colors.blue,
                ),
                ElevatedButton(
                  onPressed: () {
                    connectedDevice();
                  },
                  child: Text("Hubungkan Ke Perangkat"),
                ),
                ElevatedButton(
                    onPressed: () {
                      addDataPoint(_dataPoints);
                    },
                    child: Text("Tambah Data")),
                Container(
                    child: SfCartesianChart(
                        trackballBehavior: TrackballBehavior(
                            enable: true,
                            activationMode: ActivationMode.singleTap,
                            lineType: TrackballLineType.vertical,
                            tooltipSettings: InteractiveTooltip(
                                enable: true,
                                color: Colors.red,
                                textStyle: TextStyle(color: Colors.white))),
                        primaryXAxis: CategoryAxis(
                          autoScrollingDelta: 5,
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: 255,
                        ),
                        zoomPanBehavior: ZoomPanBehavior(
                          enablePinching: true,
                          enablePanning: true,
                          zoomMode: ZoomMode.x, // Membatasi zoom pada sumbu X
                          enableSelectionZooming: true,
                        ),
                        title: ChartTitle(text: 'Half yearly sales analysis'),
                        legend: Legend(isVisible: true),
                        tooltipBehavior: _tooltipBehavior,
                        series: <LineSeries<DataPoint, String>>[
                      LineSeries<DataPoint, String>(
                          dataSource: _dataPoints,
                          xValueMapper: (DataPoint value, _) =>
                              value.pulse.toString(),
                          yValueMapper: (__, _) => (Random().nextInt(256)),

                          // Enable data label
                          dataLabelSettings: DataLabelSettings(isVisible: true))
                    ]))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DataPoint {
  DataPoint(this.value, this.pulse);
  final double value; // Menyimpan nilai angka
  final int pulse; // Menyimpan waktu penerimaan data
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}
