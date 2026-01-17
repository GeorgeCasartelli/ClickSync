//
//  AppNavBar.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//
import SwiftUI

struct AppNavBar: View {
    @Binding var showNetworkView: Bool
    @Environment(\.horizontalSizeClass) private var hSize
    private var isPhone:Bool {hSize == .compact}
    @EnvironmentObject private var multipeerManager: MultipeerManager
    
    var body: some View{
        ZStack(alignment: .top) {
            //            Color(red: 0.06, green: 0.06, blue: 0.06)
            //                .ignoresSafeArea()
            //
            
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Button(action: {showNetworkView = true}) {
                        Image(systemName: "wifi")
                            .foregroundColor(.orange)
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
                    
                    Button(action: {showNetworkView = true}) {
                        Image(systemName: "gear")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)

                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 2)
                    
                    
                
            }
            .frame(maxWidth: .infinity)
            .background(Color.teal.opacity(0.4), ignoresSafeAreaEdges: .top)
//            .ignoresSafeArea(edges: .top)
            
        }
    }
}
