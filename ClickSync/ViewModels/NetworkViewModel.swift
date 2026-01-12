//
//  Untitled.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI
import Combine

class NetworkViewModel: ObservableObject {
    
    @Published var peers: [String] = []
    @Published var role: DeviceRole = .none
    
    private var cancellables = Set<AnyCancellable>()
    private let manager: MultipeerManager
    
    init(manager: MultipeerManager) {
        self.manager = manager
        
        manager.$connectedPeers
            .assign(to: \.peers, on: self)
            .store(in: &cancellables)
        
        manager.$role
            .receive(on: DispatchQueue.main)
            .assign(to: \.role, on: self)
            .store(in: &cancellables)
    }
    
    func startAsMaster() {manager.startAsMaster()}
    func startAsClient() {manager.startAsClient()}
    func disconnect() {manager.stop()}
    func sendStartCommand() {manager.sendCommand(["action": "start", "sender": "\(role)"])}
    func sendStopCommand() {manager.sendCommand(["action": "stop", "sender": "\(role)"])}
    
}
