//
//  BLEListViewController.swift
//  CoreBluetoothPractice
//
//  Created by 이재은 on 19/04/2019.
//  Copyright © 2019 Jaeeun Lee. All rights reserved.
//

import UIKit
import CoreBluetooth

final class BLEListViewController: UITableViewController {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    private var reuseIdentifier = "peripheralTabelCell"
    
    @IBOutlet weak var stopButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle("Scanning Devices..")
        centralManager = CBCentralManager(delegate: self,
                                          queue: DispatchQueue(label: "BLE_QUEUE"),
                                          options: nil)
    }
    
    private func scanBluetooth() {
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    private func updateTitle(_ text: String) {
        title = text
    }
    
    @IBAction func stop(_ sender: Any) {
        stopButtonItem.isEnabled = false
        centralManager?.stopScan()
        updateTitle("Found \(peripherals.count) Devices")
    }
    
    @IBAction func refresh(_ sender: Any) {
        stopButtonItem.isEnabled = true
        peripherals.removeAll()
        tableView.reloadData()
        scanBluetooth()
    }
    
    // MARK: - TableViewDataSource
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath)
        
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name == nil ? peripheral.identifier.uuidString : peripheral.name
        cell.detailTextLabel?.text = "\(peripheral.state)=\(peripheral.state.rawValue)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripherals[indexPath.row]
        stop(peripheral)
        centralManager?.connect(peripheral, options: nil)
    }
    
}

extension BLEListViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state.hashValue)")
        if central.state == .poweredOn {
            scanBluetooth()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("peripheral didDisconnectPeripheral: \(peripheral), error: \(error.debugDescription)")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("peripheral didConnect: \(peripheral), peripheral: \(peripheral)")
        peripheral.discoverServices(nil)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        print("peripheral: \(peripheral), rssi: \(RSSI)")
        
        let exist = peripherals.contains { (peri) -> Bool in
            return peri.identifier.uuidString == peripheral.identifier.uuidString
        }
        
        if !exist {
            peripherals.append(peripheral)
            
            DispatchQueue.main.async { [weak self] in
                self?.updateTitle("Scanning Devices..\(String(describing: self?.peripherals.count))")
                self?.tableView.reloadData()
            }
        }
    }
}

