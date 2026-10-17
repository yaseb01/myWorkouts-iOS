import Foundation
import CoreBluetooth

@Observable
final class SensorManager: NSObject {
    var isConnected = false
    var isScanning = false
    var currentHeartRate: Int = 0
    var batteryLevel: Int = -1
    var deviceName: String = ""
    var errorMessage: String?
    var bluetoothState: String = "Unknown"
    var lastDisconnectionTime: Date?
    var reconnectionAttempts: Int = 0

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var reconnectWorkItem: DispatchWorkItem?

    private let hrServiceUUID = CBUUID(string: "180D")
    private let hrMeasurementUUID = CBUUID(string: "2A37")
    private let batteryServiceUUID = CBUUID(string: "180F")
    private let batteryLevelUUID = CBUUID(string: "2A19")

    /// Maximum automatic reconnection attempts after a lost connection.
    private let maxReconnectionAttempts = 5

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager?.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }
        isScanning = true
        reconnectionAttempts = 0
        reconnectWorkItem?.cancel()
        centralManager?.scanForPeripherals(withServices: [hrServiceUUID], options: nil)
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }

    func disconnect() {
        reconnectWorkItem?.cancel()
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    func manualReconnect() {
        guard let peripheral = connectedPeripheral else {
            // Nothing to reconnect to - start a fresh scan instead.
            startScanning()
            return
        }
        reconnectionAttempts += 1
        centralManager?.connect(peripheral, options: nil)
    }
}

// MARK: - CBPeripheralDelegate

extension SensorManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }

        if characteristic.uuid == hrMeasurementUUID, data.count >= 2 {
            let flags = data[0]
            var hr: Int = 0
            if flags & 0x01 == 0 {
                hr = Int(data[1])
            } else if data.count >= 3 {
                hr = Int(UInt16(data[1]) | (UInt16(data[2]) << 8))
            }
            currentHeartRate = hr
        } else if characteristic.uuid == batteryLevelUUID,
                  data.count >= 1 {
            batteryLevel = Int(data[0])
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == hrServiceUUID {
                peripheral.discoverCharacteristics([hrMeasurementUUID], for: service)
            } else if service.uuid == batteryServiceUUID {
                peripheral.discoverCharacteristics([batteryLevelUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid {
            case hrMeasurementUUID:
                // Subscribe to live heart rate notifications.
                peripheral.setNotifyValue(true, for: characteristic)
            case batteryLevelUUID:
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            default:
                break
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension SensorManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothState = "Powered On"
            errorMessage = nil
        case .poweredOff:
            bluetoothState = "Powered Off"
            errorMessage = "Bluetooth is turned off"
        case .unauthorized:
            bluetoothState = "Unauthorized"
            errorMessage = "Bluetooth is not authorized"
        case .unsupported:
            bluetoothState = "Unsupported"
            errorMessage = "Bluetooth is not supported"
        case .resetting:
            bluetoothState = "Resetting"
        case .unknown:
            bluetoothState = "Unknown"
        @unknown default:
            bluetoothState = "Unknown"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral
        deviceName = peripheral.name ?? "Unknown"
        central.connect(peripheral, options: nil)
        stopScanning()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        errorMessage = nil
        reconnectionAttempts = 0
        reconnectWorkItem?.cancel()
        peripheral.delegate = self
        peripheral.discoverServices([hrServiceUUID, batteryServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        currentHeartRate = 0
        lastDisconnectionTime = Date()

        guard connectedPeripheral != nil else { return }
        guard reconnectionAttempts < maxReconnectionAttempts else {
            errorMessage = "Lost connection to heart rate sensor"
            return
        }

        reconnectionAttempts += 1
        // Exponential backoff: 2s, 4s, 8s, 16s, 30s.
        let delay = min(pow(2.0, Double(reconnectionAttempts)), 30.0)
        let work = DispatchWorkItem { [weak self] in
            guard let self, let target = self.connectedPeripheral, !self.isConnected else { return }
            central.connect(target, options: nil)
        }
        reconnectWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
