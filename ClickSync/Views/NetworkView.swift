//
//  NetwokView.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct NetworkView: View {
    @EnvironmentObject var viewModel: NetworkViewModel
    
    var body: some View {
        ZStack {
            Color(.orange)
                .opacity(0.3)
                .ignoresSafeArea()
            
            VStack{
                
                if viewModel.role == .none {
                    VStack(spacing: 20) {
                        Text("Choose role: ")
                            .generalTextStyle()
                            .foregroundStyle(.white)
                        
                        Button("Start as Master") {
                            viewModel.startAsMaster()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        
                        Button("Join as Client") {
                            viewModel.startAsClient()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                } else {
                    Text("Role: \(viewModel.role == .master ? "Master" : "Client")")
                        .font(.headline)
                        .foregroundColor(viewModel.role == .master ? .purple : .blue)
                    
                    Button("Disconnect") {
                        viewModel.disconnect()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            
                Divider()
                
                Text("Connected Devices:").generalTextStyle()
                    .font(.headline)
                if viewModel.peers.isEmpty {
                    Text("No devices connected").generalTextStyle()
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.peers, id: \.self) { peer in
                        Text(peer)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}
