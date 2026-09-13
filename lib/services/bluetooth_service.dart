import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import '../core/utils/log.dart';

enum BleConnectionState { disconnected, scanning, connecting, connected }

class WifiNetwork {
  final String ssid;
  final bool secure;
  const WifiNetwork({required this.ssid, required this.secure});

  factory WifiNetwork.fromJson(Map<String, dynamic> json) => WifiNetwork(
        ssid: json['ssid'] as String,
        secure: json['secure'] as bool? ?? true,
      );
}

/// Watches for the feeder over BLE and connects automatically while
/// [startWatching] is active -- callers drive that from app foreground/
/// background so pairing is seamless exactly as long as the app is open,
/// and the radio isn't kept busy scanning while backgrounded.
class BluetoothService {
  static const _deviceName = 'ESP_FEEDER';
  static const _serviceUuidFragment = '00ff';
  static const _wifiCharUuidFragment = 'ff01';
  static const _wifiScanCharUuidFragment = 'ff02';
  static const _scanWindow = Duration(seconds: 10);

  ble.BluetoothDevice? _device;
  ble.BluetoothCharacteristic? _wifiCharacteristic;
  ble.BluetoothCharacteristic? _wifiScanCharacteristic;
  StreamSubscription<List<ble.ScanResult>>? _scanSubscription;
  StreamSubscription<ble.BluetoothConnectionState>? _deviceStateSubscription;
  StreamSubscription<ble.BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<int>>? _wifiScanValueSubscription;
  Timer? _rescanTimer;
  bool _watching = false;

  final _wifiNetworksController = StreamController<List<WifiNetwork>>.broadcast();
  Stream<List<WifiNetwork>> get wifiNetworks => _wifiNetworksController.stream;
  List<WifiNetwork> _lastWifiNetworks = [];
  List<WifiNetwork> get lastWifiNetworks => _lastWifiNetworks;

  final _stateController = StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get state => _stateController.stream;
  BleConnectionState _currentState = BleConnectionState.disconnected;
  BleConnectionState get currentState => _currentState;
  bool get isConnected => _currentState == BleConnectionState.connected;

  void _setState(BleConnectionState s) {
    if (_currentState == s) return;
    _currentState = s;
    _stateController.add(s);
  }

  BluetoothService() {
    _adapterStateSubscription = ble.FlutterBluePlus.adapterState.listen((adapterState) {
      if (adapterState == ble.BluetoothAdapterState.on && _watching) {
        _scanForDevice();
      }
    });
  }

  Future<void> startWatching() async {
    if (_watching) return;
    _watching = true;
    if (_currentState == BleConnectionState.disconnected) {
      _scanForDevice();
    }
  }

  Future<void> stopWatching() async {
    _watching = false;
    _rescanTimer?.cancel();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await ble.FlutterBluePlus.stopScan();
    if (_currentState == BleConnectionState.scanning) {
      _setState(BleConnectionState.disconnected);
    }
  }

  Future<void> _scanForDevice() async {
    if (_currentState == BleConnectionState.connected ||
        _currentState == BleConnectionState.connecting ||
        _currentState == BleConnectionState.scanning) {
      // A quick disconnect during discoverServices() can fire both the
      // device's connectionState listener and the connect() catch block in
      // the same tick, each calling this -- this guard collapses that to
      // one scan cycle instead of two overlapping ones.
      return;
    }
    if (ble.FlutterBluePlus.adapterStateNow != ble.BluetoothAdapterState.on) {
      // Adapter listener above will retry once it turns on.
      return;
    }

    _setState(BleConnectionState.scanning);
    try {
      await ble.FlutterBluePlus.startScan(timeout: _scanWindow);
    } catch (e) {
      logDebug('BLE: startScan failed: $e');
    }

    await _scanSubscription?.cancel();
    _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.platformName == _deviceName) {
          ble.FlutterBluePlus.stopScan();
          _connect(result.device);
          return;
        }
      }
    }, onError: (e) {
      logDebug('BLE: scan error: $e');
    });

    _rescanTimer?.cancel();
    _rescanTimer = Timer(_scanWindow + const Duration(seconds: 1), () {
      if (_watching && _currentState == BleConnectionState.scanning) {
        _scanForDevice();
      }
    });
  }

  Future<void> _connect(ble.BluetoothDevice device) async {
    _setState(BleConnectionState.connecting);
    _device = device;
    try {
      await _deviceStateSubscription?.cancel();
      _deviceStateSubscription = device.connectionState.listen((connState) {
        if (connState == ble.BluetoothConnectionState.disconnected) {
          _wifiCharacteristic = null;
          _wifiScanCharacteristic = null;
          _wifiScanValueSubscription?.cancel();
          _setState(BleConnectionState.disconnected);
          if (_watching) _scanForDevice();
        }
      });

      // Personal/hobby project, not for-profit -- nonprofit license applies.
      // See flutter_blue_plus's LICENSE for terms if this project's use ever changes.
      await device.connect(license: ble.License.nonprofit, timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase().contains(_serviceUuidFragment),
        orElse: () => throw StateError('Feeder BLE service not found'),
      );
      _wifiCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase().contains(_wifiCharUuidFragment),
        orElse: () => throw StateError('Feeder WiFi characteristic not found'),
      );

      // Optional: older firmware may not have this characteristic yet.
      // Absence just means the WiFi dialog falls back to manual SSID entry.
      try {
        _wifiScanCharacteristic = service.characteristics.firstWhere(
          (c) => c.uuid.toString().toLowerCase().contains(_wifiScanCharUuidFragment),
        );
        await _wifiScanCharacteristic!.setNotifyValue(true);
        await _wifiScanValueSubscription?.cancel();
        _wifiScanValueSubscription = _wifiScanCharacteristic!.lastValueStream.listen(_handleWifiScanValue);
        // Firmware populates this a moment after connect -- read whatever it
        // has now too, in case the notify arrives before this listener does.
        final initial = await _wifiScanCharacteristic!.read();
        _handleWifiScanValue(initial);
      } catch (e) {
        logDebug('BLE: WiFi scan characteristic unavailable: $e');
      }

      _setState(BleConnectionState.connected);
    } catch (e) {
      logDebug('BLE: connect failed: $e');
      _setState(BleConnectionState.disconnected);
      if (_watching) _scanForDevice();
    }
  }

  void _handleWifiScanValue(List<int> bytes) {
    if (bytes.isEmpty) return;
    try {
      final data = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
      final networks = (data['networks'] as List)
          .map((n) => WifiNetwork.fromJson(n as Map<String, dynamic>))
          .toList();
      _lastWifiNetworks = networks;
      _wifiNetworksController.add(networks);
    } catch (e) {
      logDebug('BLE: failed to parse WiFi scan payload: $e');
    }
  }

  /// Sends SSID and password as two separate writes, matching the firmware's
  /// CharacteristicCallbacks::onWrite exactly (it checks startsWith("ssid:")
  /// and startsWith("pass:") as independent branches). The previous version
  /// sent one combined "ssid:X,pass:Y" write, which the firmware parsed
  /// entirely as the SSID -- the password was never actually set this way.
  /// Firmware connects automatically once it receives the "pass:" write; no
  /// reboot command exists or is needed.
  Future<bool> sendWifiCredentials(String ssid, String password) async {
    if (_wifiCharacteristic == null) return false;
    try {
      await _wifiCharacteristic!.write(utf8.encode('ssid:$ssid'), withoutResponse: false);
      await _wifiCharacteristic!.write(utf8.encode('pass:$password'), withoutResponse: false);
      return true;
    } catch (e) {
      logDebug('BLE: failed to send WiFi credentials: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    await stopWatching();
    await _deviceStateSubscription?.cancel();
    await _adapterStateSubscription?.cancel();
    await _wifiScanValueSubscription?.cancel();
    await _device?.disconnect();
    await _stateController.close();
    await _wifiNetworksController.close();
  }
}
