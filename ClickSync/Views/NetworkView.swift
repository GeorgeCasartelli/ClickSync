//
//  NetwokView.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct NetworkView: View {
    @StateObject var multipeerManager: MultipeerManager
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()
            
            VStack{
                Text("Network view").mainStyle()
                if multipeerManager.role == .none {
                    VStack(spacing: 20) {
                        Text("Choose Role:")
                            .font(.headline)
                        
                        Button("Start as Master") {
                            multipeerManager.startAsMaster()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        
                        Button("Join as Client") {
                            multipeerManager.startAsClient()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                } else {
                    // Show current role
                    Text("Role: \(multipeerManager.role == .master ? "Master" : "Client")")
                        .font(.headline)
                        .foregroundColor(multipeerManager.role == .master ? .purple : .blue)
                    
                    Button("Disconnect") {
                        multipeerManager.stop()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                
                Divider()
                
                Text("Connected Devices:").generalTextStyle()
                    .font(.headline)
                if multipeerManager.connectedPeers.isEmpty {
                    Text("No devices connected").generalTextStyle()
                        .foregroundColor(.gray)
                } else {
                    ForEach(multipeerManager.connectedPeers, id: \.self) { peer in
                        Text(peer)
                            .foregroundColor(.green)
                    }
                }
                
                Button {
                    multipeerManager.sendCommand(["action": "start", "sender": "master"])
                } label: {
                    Text("Send command").generalTextStyle()
                }
                
                Button {
                    multipeerManager.sendCommand(["action": "stop", "sender": "master"])
                } label: {
                    Text("Send command").generalTextStyle()
                }
            }
        }
    }
}
