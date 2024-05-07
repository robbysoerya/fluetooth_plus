package app.iandis.fluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.util.Log
import java.io.OutputStream
import java.lang.Exception
import java.util.UUID

class FluetoothManager(private val _adapter: BluetoothAdapter?) {

    // Standard SerialPortService ID
    private var _uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
//    private var _connectedDevice: MutableList<BluetoothDevice> = mutableListOf()
    private var _socket: MutableList<BluetoothSocket> = mutableListOf()
    private val _executor: SerialExecutor = SerialExecutor()

    /**
     * @return **true** when enabled, **false** when disabled, **null** when not supported
     * */
    val isAvailable: Boolean get() = _adapter?.isEnabled ?: false

    /**
     * @return **true** when device connected, **false** when not connected
     * */

    fun isConnected(deviceAddress: String): Boolean {
        return _socket.any { it.remoteDevice.address == deviceAddress && it.isConnected }
    }

    /**
     * @return **MutableList<Map<String, String>>** of connected device
     * */

    val connectedDevice: MutableList<Map<String, String>>
        get() = _socket.map {
            it.remoteDevice.toMap()
        }.toMutableList()

    fun getAvailableDevices(): List<Map<String, String>> {
        val devicesMap: MutableList<Map<String, String>> = mutableListOf()
        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices
        if (bondedDevices.isNotEmpty()) {
            for (device: BluetoothDevice in bondedDevices) {
                devicesMap.add(device.toMap())
            }
        }
        return devicesMap
    }

    fun send(bytes: ByteArray, deviceAddress: String, onComplete: () -> Unit, onError: (Throwable) -> Unit) {

        _executor.execute {
            try {
                if (!isConnected(deviceAddress)) {
                    disconnectDevice(deviceAddress)
                    onError(Exception("No device connected!"))
                    return@execute
                }

                // Find the socket associated with the device
                val socket = _socket.find { it.remoteDevice.address == deviceAddress }

                socket?.let {
                    val os: OutputStream = it.outputStream
                    os.write(bytes)
                    os.flush()
                    onComplete()
                } ?: run {
                    onError(Exception("Socket not found for device $deviceAddress"))
                    return@execute
                }
            } catch (t: Throwable) {
                disconnectDevice(deviceAddress)
                onError(t)
                return@execute
            }
        }

    }

    @Synchronized
    fun connect(
        deviceAddress: String,
        onResult: (BluetoothDevice) -> Unit,
        onError: (Throwable) -> Unit
    ) {

        val existingDevice = _socket.find { it.remoteDevice.address == deviceAddress }

        if (existingDevice != null) {

            try {
                existingDevice.connect()
            } catch (t: Throwable) {
                Log.d("connect", "device can't connect")
                disconnectDevice(deviceAddress)
                onError(t)
                return
            }

            if (existingDevice.isConnected) {
                Log.d("connect", "device already connected")
                onResult(existingDevice.remoteDevice)
                return
            } else {
                Log.d("connect", "device not connected")
                onError(Exception("Device not connected"))
                return
            }
        }

        val bondedDevices: Set<BluetoothDevice> = _adapter!!.bondedDevices

        val currentDevice: BluetoothDevice? = bondedDevices.find { it.address == deviceAddress }

        if (currentDevice == null) {
            onError(Exception("Device not found"))
            return
        }

        _executor.execute {
            try {
                val mSocket = connect(currentDevice)
                _socket.add(mSocket)
                onResult(currentDevice)
                return@execute
            } catch (t: Throwable) {
                Log.d("connect", "device error to connect")
                disconnectDevice(deviceAddress)
                onError(t)
                return@execute
            }
        }
    }

    private fun closeSocket() {
        for (socket: BluetoothSocket in _socket) {
            val os: OutputStream = socket.outputStream
            os.close()
            socket.close()
        }
    }

    private fun closeSocket(socket: BluetoothSocket) {
        try {
            val os: OutputStream = socket.outputStream
            os.close()
            socket.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun connect(device: BluetoothDevice): BluetoothSocket {
        val mSocket = device.createRfcommSocketToServiceRecord(_uuid)
        mSocket.connect()
        return mSocket
    }

    fun disconnect() {
        closeSocket()
        _socket.clear()
    }

    fun disconnectDevice(deviceAddress: String) {
        val iteratorSocket = _socket.iterator()
        while (iteratorSocket.hasNext()) {
            val socket = iteratorSocket.next()
            if (socket.remoteDevice.address == deviceAddress) {
                closeSocket(socket)
                iteratorSocket.remove()
                break
            }
        }
    }

    fun dispose() {
        disconnect()
        _executor.shutdown()
    }
}