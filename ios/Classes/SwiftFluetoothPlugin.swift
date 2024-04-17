import Flutter
import CoreBluetooth

public class SwiftFluetoothPlugin: NSObject, FlutterPlugin {
    private static let _channelName: String! = "fluetooth/main"
    
    private var _fluetoothManager: FluetoothManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel: FlutterMethodChannel = FlutterMethodChannel(
            name: _channelName,
            binaryMessenger: registrar.messenger()
        )
        
        let instance: SwiftFluetoothPlugin = SwiftFluetoothPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if _fluetoothManager == nil {
            _fluetoothManager = FluetoothManager()
        }
        switch call.method {
        case "isAvailable":
            let isAvailable: Bool = _fluetoothManager!.isAvailable
            result(isAvailable)
        case "isConnected":
            guard let uuidString: String = call.arguments as? String else {
                result(FluetoothError(message: "Invalid argument for method [isConnected]").toFlutterError())
                return
            }
             _fluetoothManager!.isConnected(uuidString,resultCallback: result)
        case "connectedDevice":
            _fluetoothManager!.getConnectedDevices(result)
        case "getAvailableDevices":
            _fluetoothManager!.getAvailableDevices(result)
       case "connect":
           guard let targetDevice = call.arguments as? String else {
               result(FluetoothError(message: "targetDevice should be a string").toFlutterError())
               return
           }
           if !_fluetoothManager!.isAvailable {
               result(FluetoothError(message: "Bluetooth is not available.").toFlutterError())
               return
           }
           _fluetoothManager!.connect(
               uuidString: targetDevice,
               resultCallback: { device in
                   guard let connectedDevice = device as? [String: String] else {
                       result(FluetoothError(message: "Failed to connect to \(targetDevice)").toFlutterError())
                       return
                   }
                   result(connectedDevice)
               }
           )
        case "disconnectDevice":
            guard let uuidString: String = call.arguments as? String else {
                result(FluetoothError(message: "Invalid argument for method [disconnectDevice]").toFlutterError())
                return
            }
            _fluetoothManager!.disconnectDevice(uuidString,resultCallback: result)
        case "disconnect":
            _fluetoothManager!.disconnect(result)
        case "sendBytes":
            guard let data: [String:Any] = call.arguments as? [String:Any] else {
                result(FluetoothError(message: "Invalid argument for method [sendBytes]").toFlutterError())
                return
            }
            
            guard let bytes: FlutterStandardTypedData = data["bytes"] as? FlutterStandardTypedData,
                    let uuidString: String = data["device"] as? String else {
                result(FluetoothError(message: "Invalid payload for ['bytes']").toFlutterError())
                return
            }
            _fluetoothManager!.sendBytes(bytes.data, uuidString: uuidString, resultCallback: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
