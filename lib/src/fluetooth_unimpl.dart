import 'fluetooth.dart';
import 'fluetooth_device.dart';

class FluetoothImpl implements Fluetooth {
  factory FluetoothImpl() => _instance;

  const FluetoothImpl._();

  static const FluetoothImpl _instance = FluetoothImpl._();

  @override
  Future<FluetoothDevice> connect(String deviceId) {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<List<FluetoothDevice>> get connectedDevice {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<void> disconnect() {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<List<FluetoothDevice>> getAvailableDevices() {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<bool> get isAvailable {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<bool> isConnected(String deviceId) {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<void> sendBytes(List<int> bytes, String deviceId) {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }

  @override
  Future<void> disconnectDevice(String deviceId) {
    throw UnsupportedError('Fluetooth is not supported on this platform');
  }
}
