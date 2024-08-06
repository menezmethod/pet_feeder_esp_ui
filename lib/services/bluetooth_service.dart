import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';

class BluetoothService {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _wifiCharacteristic;

  Future<void> connectToBluetoothDevice() async {
    await _flutterBlue.startScan(timeout: Duration(seconds: 5));
    var subscription = _flutterBlue.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.name == 'ESP_FEEDER') {
          await _flutterBlue.stopScan();
          _connectedDevice = result.device;
          await _connectedDevice!.connect();
          await _discoverServices();
          break;
        }
      }
    });
    await subscription.cancel();
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;
    var services = await _connectedDevice!.discoverServices();
    var service = services.firstWhere((s) => s.uuid.toString() == '00FF');
    _wifiCharacteristic = service.characteristics.firstWhere((c) => c.uuid.toString() == 'FF01');
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    if (_wifiCharacteristic == null) return;
    String credentials = 'ssid:$ssid,pass:$password';
    await _wifiCharacteristic!.write(utf8.encode(credentials));
    await _wifiCharacteristic!.write(utf8.encode("reboot"));
  }
}