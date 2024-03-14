package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FluetoothPlugin : FlutterPlugin, MethodCallHandler {
    private val _channelName: String = "fluetooth/main"
    private lateinit var _channel: MethodChannel
    private var _fluetoothManager: FluetoothManager? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, _channelName)
        _channel.setMethodCallHandler(this)
        val context: Context = flutterPluginBinding.applicationContext
        val bluetoothManager: BluetoothManager? =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        val adapter: BluetoothAdapter? = bluetoothManager?.adapter
        _fluetoothManager = FluetoothManager(adapter)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "isAvailable" -> {
                    val isAvailable: Boolean = _fluetoothManager!!.isAvailable
                    result.success(isAvailable)
                }
                "isConnected" -> {
                    val targetDevice: Any = call.arguments
                    if (targetDevice is String) {
                        val isConnected: Boolean = _fluetoothManager!!.isConnected(targetDevice)
                        result.success(isConnected)
                    }

                }
                "connectedDevice" -> {
                    val connectedDevice: MutableList<Map<String, String>> = _fluetoothManager!!.connectedDevice
                    result.success(connectedDevice)
                }
                "getAvailableDevices" -> {
                    val availableDevices: List<Map<String, String>> =
                        _fluetoothManager!!.getAvailableDevices()
                    result.success(availableDevices)
                }
                "connect" -> {
                    if (!_fluetoothManager!!.isAvailable) {
                        throw Exception("Bluetooth is not available.")
                    }
                    val targetDevice: Any = call.arguments
                    if (targetDevice is String) {
                        _fluetoothManager!!.connect(targetDevice, { device ->
                            val connectedDevice: Map<String, String> = device.toMap()
                            result.success(connectedDevice)
                        }, {
                            result.error(
                                "FLUETOOTH_CONNECT_ERROR",
                                "Failed to connect to $targetDevice",
                                null
                            )
                        })
                    } else {
                        throw IllegalArgumentException("targetDevice should be a string")
                    }
                }
                "disconnect" -> {
                    _fluetoothManager!!.disconnect()
                    result.success(true)
                }
                "sendBytes" -> {
                    if (!_fluetoothManager!!.isAvailable) {
                        throw Exception("Bluetooth is not available.")
                    }

                    val arguments: Any = call.arguments
                    if (arguments is Map<*, *>) {
                        val bytes: ByteArray = arguments["bytes"] as ByteArray
                        val deviceAddress: String = arguments["device"] as String

                        if (!_fluetoothManager!!.isConnected(deviceAddress)) {
                            throw Exception("Not connected!")
                        }

                        _fluetoothManager!!.send(bytes,deviceAddress, {
                            result.success(true)
                        }, {
                            result.error("FLUETOOTH_ERROR", it.message, it.cause)
                        })
                    } else {
                        throw IllegalArgumentException("arguments should be a Map")
                    }
                }
                "disconnectDevice" -> {
                    val targetDevice: Any = call.arguments
                    if (targetDevice is String) {
                        _fluetoothManager!!.disconnectDevice(targetDevice)
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error(
                "FLUETOOTH_ERROR",
                e.message,
                e.cause
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        _channel.setMethodCallHandler(null)
        _fluetoothManager!!.dispose()
        _fluetoothManager = null
    }
}
