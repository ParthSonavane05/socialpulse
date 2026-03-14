package com.example.socialpulse

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Handler
import android.os.Looper

/**
 * BLE scanner that counts nearby Bluetooth devices to infer social context.
 * ≥3 devices likely means a social interaction (meeting, dinner, etc.)
 */
class BluetoothScanner(private val context: Context) {

    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter
    private var scanner: BluetoothLeScanner? = null
    private val discoveredDevices = mutableSetOf<String>()
    private var isScanning = false

    private var scanCallback: ScanCallback? = null

    /**
     * Check if Bluetooth is available and enabled.
     */
    @SuppressLint("MissingPermission")
    fun isAvailable(): Boolean {
        return bluetoothAdapter != null && bluetoothAdapter.isEnabled
    }

    /**
     * Start a BLE scan for [durationMs] milliseconds.
     * Calls [onComplete] with the count of unique nearby devices.
     */
    @SuppressLint("MissingPermission")
    fun scan(durationMs: Long = 10_000, onComplete: (Int) -> Unit) {
        if (!isAvailable()) {
            onComplete(0)
            return
        }

        if (isScanning) {
            onComplete(discoveredDevices.size)
            return
        }

        discoveredDevices.clear()
        scanner = bluetoothAdapter?.bluetoothLeScanner

        if (scanner == null) {
            onComplete(0)
            return
        }

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult?) {
                result?.device?.address?.let { address ->
                    discoveredDevices.add(address)
                }
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>?) {
                results?.forEach { result ->
                    result.device?.address?.let { address ->
                        discoveredDevices.add(address)
                    }
                }
            }

            override fun onScanFailed(errorCode: Int) {
                isScanning = false
                onComplete(0)
            }
        }

        try {
            isScanning = true
            scanner?.startScan(scanCallback)

            Handler(Looper.getMainLooper()).postDelayed({
                stopScan()
                onComplete(discoveredDevices.size)
            }, durationMs)
        } catch (e: Exception) {
            isScanning = false
            onComplete(0)
        }
    }

    /**
     * Stop an ongoing scan.
     */
    @SuppressLint("MissingPermission")
    fun stopScan() {
        if (isScanning && scanCallback != null) {
            try {
                scanner?.stopScan(scanCallback)
            } catch (_: Exception) {}
            isScanning = false
        }
    }

    /**
     * Get the count of devices from the last scan (without starting a new one).
     */
    fun getLastScanCount(): Int {
        return discoveredDevices.size
    }
}
