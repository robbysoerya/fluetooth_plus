import 'dart:async';
import 'dart:developer';

import 'package:esc_pos_gen/esc_pos_gen.dart';
import 'package:fluetooth/fluetooth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Completer<CapabilityProfile> _profileCompleter =
      Completer<CapabilityProfile>();

  bool _isBusy = false;
  List<FluetoothDevice> _devices = [];
  List<FluetoothDevice> _connectedDevice = [];

  @override
  void initState() {
    super.initState();
    CapabilityProfile.load().then(_profileCompleter.complete);
    _refreshPrinters();
  }

  @override
  void dispose() {
    Fluetooth().disconnect();
    super.dispose();
  }

  Future<void> _refreshPrinters() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    await Fluetooth().getAvailableDevices().then((value) {
      _devices = value;
    });
    setState(() {
      _isBusy = false;
    });
  }

  Future<void> _connect(FluetoothDevice device) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);

    try {
      await Fluetooth().connect(
        device.id,
      );
    } catch (e) {
      log(e.toString());
    }

    await Fluetooth().connectedDevice.then((value) {
      _connectedDevice = value;
    });

    setState(() {
      _isBusy = false;
    });
  }

  Future<void> _disconnect(FluetoothDevice device) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    await Fluetooth().disconnectDevice(device.id);
    await Fluetooth().connectedDevice.then((value) {
      _connectedDevice = value;
    });
    setState(() {
      _isBusy = false;
    });
  }

  void showPrintDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _connectedDevice.map<Widget>((device) {
                return ListTile(
                  title: Text(device.name),
                  onTap: () => _print(deviceId: device.id),
                );
              }).toList()
                ..add(ListTile(
                  title: const Text('Semua'),
                  onTap: () => _print(),
                )),
            ),
          ),
        );
      },
    );
  }

  Future<void> _print({String? deviceId}) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final CapabilityProfile profile = await _profileCompleter.future;
    final Generator generator = Generator(PaperSize.mm58, profile);
    final ByteData logoBytes = await rootBundle.load('assets/amd_logo.jpg');
    final img.Image? decodedImg = await compute(
      img.decodeJpg,
      logoBytes.buffer.asUint8List(),
    );
    final img.Image resizedImg = img.copyResize(
      decodedImg!,
      width: 80,
    );
    final List<PosComponent> components = <PosComponent>[
      PosImage(image: resizedImg),
      PosText.center('Mac Address: $deviceId'),
      const PosSeparator(),
      PosList.builder(
        count: 5,
        builder: (int i) {
          return PosList(
            <PosComponent>[
              PosRow.leftRightText(
                leftText: 'Product $i',
                leftTextStyles: const PosStyles.defaults(),
                rightText: 'Rp. $i',
              ),
              PosRow.leftRightText(
                leftText: '1 x Rp. $i',
                leftTextStyles: const PosStyles.defaults(
                  fontType: PosFontType.fontB,
                ),
                rightText: 'Rp. $i',
                rightTextStyles: const PosStyles.defaults(
                  align: PosAlign.right,
                  fontType: PosFontType.fontB,
                ),
              ),
            ],
          );
        },
      ),
      const PosSeparator(),
      PosBarcode.code128('{A12345'.split('')),
      const PosSeparator(),
      const PosFeed(1),
      const PosCut(),
    ];

    final Paper paper = Paper(
      generator: generator,
      components: components,
    );

    if (deviceId == null) {
      for (var device in _connectedDevice) {
        try {
          await Fluetooth().sendBytes(paper.bytes, device.id);
        } catch (_) {
          await _disconnect(device);
        }
      }
    } else {
      for (var device in _connectedDevice) {
        if (device.id == deviceId) {
          try {
            await Fluetooth().sendBytes(paper.bytes, device.id);
          } catch (_) {
            await _disconnect(device);
          }
          break;
        }
      }
    }

    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          TextButton(
            onPressed: _connectedDevice.isNotEmpty && !_isBusy
                ? showPrintDialog
                : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
            ),
            child: const Text('Print'),
          ),
          IconButton(
            onPressed: _refreshPrinters,
            color: Colors.amber,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemBuilder: (_, int index) {
                final FluetoothDevice currentDevice = _devices[index];
                if (currentDevice.name.isEmpty) return Container();
                return ListTile(
                  title: Text(currentDevice.name),
                  subtitle: Text(currentDevice.id),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _connectedDevice.contains(currentDevice)
                          ? _disconnect(currentDevice)
                          : _connect(currentDevice);
                    },
                    child: Text(
                      _connectedDevice.contains(currentDevice)
                          ? 'Disconnect'
                          : 'Connect',
                    ),
                  ),
                );
              },
              itemCount: _devices.length,
            ),
    );
  }
}
