//
//  AppNavBar.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//
import SwiftUI

// top nav bar used at the top of the app. reactive network button to show connectivity status
struct AppNavBar: View {
    @Binding var showSettingsView: Bool

    @EnvironmentObject private var multipeerManager: MultipeerManager
    
    var body: some View{
        ZStack(alignment: .top) {
            
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    // colour wifi symbol depending on connectivity status
                    let isConnected = !multipeerManager.connectedPeers.isEmpty
                    Button(action: {showSettingsView = true}) {
                        Image(systemName: "wifi")
                            .foregroundColor(!isConnected ? .orange : multipeerManager.role == .master ? .purple : (multipeerManager.role == .client ? .green : .orange))
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    ZStack {
                              
                        Text("ClickSync")
                            .mainStyle()
                            .shadow(color: .orange.opacity(0.1), radius: 5)

                    }
                    .frame(width: 200)
                    
                    
                    Spacer()
                    
                    Button(action: {showSettingsView = true}) {
                        Image(systemName: "gear")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // soft underline
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 2)
                
            }
            .frame(maxWidth: .infinity)
            .background(Color.teal.opacity(0.4), ignoresSafeAreaEdges: .top)
            
        }
    }
}
