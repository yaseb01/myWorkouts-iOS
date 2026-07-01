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

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?

    private let hrServiceUUID = CBUUID(string: "180D")
    private let hrMeasurementUUID = CBUUID(string: "2A37")
    private let batteryServiceUUID = CBUUID(string: "180F")
    private let batteryLevelUUID = CBUUID(string: "2A19")

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
        centralManager?.scanForPeripherals(withServices: [hrServiceUUID], options: nil)
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension SensorManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }

        if characteristic.uuid == hrMeasurementUUID,
           let data = characteristic.value {
            let flags = data[0]
            var hr: Int = 0
            if flags & 0x01 == 0 {
                hr = Int(data[1])
            } else {
                hr = Int(UInt16(data[1]) | (UInt16(data[2]) << 8))
            }
            currentHeartRate = hr
        } else if characteristic.uuid == batteryLevelUUID,
                  let data = characteristic.value {
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
}

// MARK: - CBCentralManagerDelegate

extension SensorManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            errorMessage = "Bluetooth is not available"
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
        peripheral.delegate = self
        peripheral.discoverServices([hrServiceUUID, batteryServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        currentHeartRate = 0
    }
}
