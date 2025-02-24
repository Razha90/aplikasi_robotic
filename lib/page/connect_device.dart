import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aplikasi_robotic/help/bluetooth.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/quickalert.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ConnectDevice extends StatefulWidget {
  const ConnectDevice({super.key, required this.connection});
  final BluetoothConnection connection;

  @override
  State<ConnectDevice> createState() => _ConnectDeviceState();
}

class _ConnectDeviceState extends State<ConnectDevice> {
  StreamSubscription? _readSubscription;
  final List<String> _receivedInput = [];
  bool isStart = false;

  double _value = 100;

  final List<DataPoint> _dataPoints = [];
  final TooltipBehavior _tooltipBehavior = TooltipBehavior();
  Timer? _debounce;
  String _fileName = "";

  @override
  void initState() {
    super.initState();
    _readSubscription = widget.connection.input?.listen((event) {
      if (mounted) {
        String rawData = utf8.decode(event);
        print("Received data: $rawData"); // Debug untuk melihat isi even
        try {
          double value = double.parse(rawData.trim());
          print("Received data: $value"); // Debug untuk melihat isi event

          int pulse = _dataPoints.isEmpty ? 1 : _dataPoints.last.pulse + 1;

          setState(() => _dataPoints.add(DataPoint(value, pulse)));
        } catch (e) {
          print("Error parsing data: $e");
        }
      }
    });

    isStart = false;
  }

  void sendData(String datas) {
    try {
      widget.connection.writeString(datas);
    } catch (e) {
      QuickAlert.show(
        disableBackBtn: true,
        onConfirmBtnTap: () {
          Navigator.pushReplacementNamed(context, '/');
        },
        context: context,
        type: QuickAlertType.warning,
        title: "Error",
        text: "Gagal mengirim data perangkat terbptus.",
      );
    }
  }

  String getRandomFileName({int length = 10}) {
    const String chars =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();

    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> exportExcel() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      print("Izin penyimpanan tidak diberikan");
      if (mounted) {
        CherryToast.warning(
          title: Text("Izin Penyiapanan dibutuhkan!",
              style:
                  GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 12)),
          action: Text(
            "Pastikan izin penyimpanan diaktifkan",
            style: GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 12),
          ),
        ).show(context);
      }
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject =
        excel['analisis-${DateTime.now().millisecondsSinceEpoch}'];
    sheetObject.appendRow([
      TextCellValue("Pulse"),
      TextCellValue("Speed"),
    ]);

    for (var row in _dataPoints) {
      sheetObject.appendRow([
        IntCellValue(row.pulse),
        DoubleCellValue(row.value),
      ]);
    }

    excel.delete('Sheet1');

    var fileBytes = excel.save();

    if (fileBytes == null) {
      print("Gagal menyimpan file");
      if (mounted) {
        CherryToast.error(
          title: Text("Gagal menyimpan file",
              style:
                  GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12)),
          action: Text(
            "Coba lagi, dan periksa izin penyimpanan",
            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
          ),
        ).show(context);
      }
      return;
    }

    Directory directory = Directory("/storage/emulated/0/Download");
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    String filePath = "${directory.path}/output-analisis.xlsx";

    File file = File(filePath);
    await file.writeAsBytes(fileBytes);

    print("File disimpan di: $filePath");
    if (mounted) {
      CherryToast.success(
        title: Text("File berhasil disimpan",
            style: GoogleFonts.poppins(color: Colors.green, fontSize: 12)),
        action: Text(
          "File disimpan di folder Download",
          style: GoogleFonts.poppins(color: Colors.green, fontSize: 12),
        ),
      ).show(context);
    }
    setState(() {
      _fileName = filePath;
    });
  }

  @override
  void dispose() {
    widget.connection.dispose();
    _readSubscription?.cancel();
    super.dispose();
  }

  void checkData() {
    print(_dataPoints[0].pulse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leadingWidth: 25,
          title: Text("Terhubung ke ${widget.connection.address}",
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text("Device Name: ${widget.connection.address}"),
                      ],
                    ),
                    !isStart
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent),
                            onPressed: () {
                              sendData(_value.toInt().toString());
                              setState(() {
                                isStart = !isStart;
                              });
                            },
                            child: Text(
                              "Mulai",
                              style: TextStyle(color: Colors.white),
                            ))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            onPressed: () {
                              sendData("0");
                              setState(() {
                                isStart = !isStart;
                              });
                            },
                            child: Text(
                              "Stop",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
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
                      maximum: 800,
                    ),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enablePanning: true,
                      zoomMode: ZoomMode.x, // Membatasi zoom pada sumbu X
                      enableSelectionZooming: true,
                    ),
                    title: ChartTitle(text: 'Analisis Kecepatan'),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: _tooltipBehavior,
                    series: <LineSeries<DataPoint, String>>[
                  LineSeries<DataPoint, String>(
                      dataSource: _dataPoints,
                      xValueMapper: (DataPoint value, _) =>
                          value.pulse.toString(), // X: Pulse
                      yValueMapper: (DataPoint value, _) => value.value,
                      dataLabelSettings: DataLabelSettings(isVisible: true))
                ])),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(_value.toInt().toString()),
                  Slider(
                    min: 0,
                    max: 250,
                    divisions: 50,
                    activeColor: Colors.purple,
                    inactiveColor: Colors.purple.shade100,
                    thumbColor: Colors.pink,
                    value: _value,
                    label: _value.toInt().toString(),
                    onChanged: (value) {
                      if (isStart) {
                        setState(() {
                          _value = value;
                        });
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(Duration(seconds: 1), () {
                          sendData(_value.toInt().toString());
                        });
                      }
                    },
                  )
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      exportExcel();
                    },
                    child: Text("Export Excel"),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _fileName != ""
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await OpenFilex.open(_fileName);
                            } catch (e) {
                              if (context.mounted) {
                                CherryToast.error(
                                  title: Text("Gagal membuka file",
                                      style: GoogleFonts.poppins(
                                          color: Colors.redAccent,
                                          fontSize: 12)),
                                  action: Text(
                                    "Coba lagi, dan periksa izin penyimpanan",
                                    style: GoogleFonts.poppins(
                                        color: Colors.redAccent, fontSize: 12),
                                  ),
                                ).show(context);
                              }
                            }
                          },
                          child: Text("Buka File Excel"),
                        ),
                      ))
                  : SizedBox(),
            )
          ],
        ));
  }
}

class DataPoint {
  DataPoint(this.value, this.pulse);
  final double value; // Menyimpan nilai angka
  final int pulse; // Menyimpan waktu penerimaan data
}
