//
//  AppNavBar.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//
import SwiftUI

struct AppNavBar: View {
    @Binding var showNetworkView: Bool
    
    var body: some View{
        ZStack(alignment: .top) {
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                   
                    Spacer()
                    Text("ClickSync")
                        .mainStyle()
                    Spacer()
                    Button(action: {showNetworkView = true}) {
                        Image(systemName: "gear")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .background(
                    Color.black.opacity(0.7)
                        .blur(radius: 10)
                )
                
                Spacer() // rest of content
            }
        }
        
    }
}
