//
//  NetwokView.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct NetworkView: View {
    @EnvironmentObject var networkVM: NetworkViewModel
    
    
    var body: some View {
        ZStack {
            Color(.orange)
                .opacity(0.3)
                .ignoresSafeArea()
            
            VStack{
                
                if networkVM.role == .none {
                    VStack(spacing: 20) {
                        Text("Choose role: ")
                            .generalTextStyle()
                            .foregroundStyle(.white)
                        
                        Button("Start as Master") {
                            networkVM.startAsMaster()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        
                        Button("Join as Client") {
                            networkVM.startAsClient()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                } else {
                    Text("Role: \(networkVM.role == .master ? "Master" : "Client")")
                        .font(.headline)
                        .foregroundColor(networkVM.role == .master ? .purple : .blue)
                    
                    Button("Disconnect") {
                        networkVM.disconnect()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            
                Divider()
                
                Text("Connected Devices:").generalTextStyle()
                    .font(.headline)
                if networkVM.peers.isEmpty {
                    Text("No devices connected").generalTextStyle()
                        .foregroundColor(.gray)
                } else {
                    ForEach(networkVM.peers, id: \.self) { peer in
                        Text(peer)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}
