import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluetooth_plus/fluetooth.dart';

void main() {
  const MethodChannel channel = MethodChannel('fluetooth');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('isAvailable', () async {
    expect(await Fluetooth().isAvailable, true);
  });
}
