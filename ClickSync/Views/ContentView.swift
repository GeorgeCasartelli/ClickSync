//
//  ContentView.swift
//  ClickSync
//
//  Created by George Casartelli on 13/11/2025.
//

import SwiftUI
import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation


extension Text {
    func mainStyle() -> some View {
        self
            .font(.system(.title, design: .monospaced))
//            .bold()
            .foregroundStyle(.orange)
            .fontWeight(.heavy)
            
            
    }
    
    func generalTextStyle() -> some View {
        self
            .font(.system(.body, design: .monospaced))
            
    }
    
    func embossedLabelStyle() -> some View {
            self
                .font(.system(.body, design: .monospaced))
                .fontWeight(.heavy)
                .foregroundColor(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)   // inner shadow (recessed)
                .shadow(color: .white.opacity(0.15), radius: 1, x: -1, y: -1) // highlight on top-left
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
        }
    
    func secondaryStyle() -> some View {
        self
            .font(.system(size: 30, design: .monospaced ))
            .fontWeight(.medium)
    }
}

struct VolumeBar: View {
    let label: String
    @Binding var value: Float
    let color: Color
    
    let minVol: Float = 0
    let maxVol: Float = 8.0
    let barHeight: Float = 120
    
    @State private var dragStartValue: Float = 1.0
  
    var body: some View {
        VStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))

            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(height: CGFloat(value / maxVol) * 120),
                    alignment: .bottom
                )
                .frame(width: 36, height: 120)
                .gesture(
                    DragGesture()
                        .onChanged { drag in
                            
                            let dragAmount = -Float(drag.translation.height) + Float(dragStartValue)
                             
                            let clamped = min(max(dragAmount, 0.0), barHeight)
                            let mapped = clamped / barHeight * maxVol
                            value = Float(mapped)

                        }
                        .onEnded { _ in
                            // nothing to persist; next drag will capture new start
                            dragStartValue = value / maxVol * barHeight

                            
                        }

                                    
                )
        }
        
    }
}



struct ContentView: View {
    @StateObject private var multipeerManager: MultipeerManager
    @StateObject private var metroVM: MetronomeView.ViewModel
    @StateObject private var networkVM: NetworkViewModel
    
    @State private var showNetworkView = false
    
    init() {
        let mpManager = MultipeerManager()
        _multipeerManager = StateObject(wrappedValue: mpManager)
        _metroVM = StateObject(wrappedValue: MetronomeView.ViewModel())
        _networkVM = StateObject(wrappedValue: NetworkViewModel(manager: mpManager))
    }
    
    var body: some View {
        //        NavigationStack {
        NavigationStack {
            ZStack{
                Color(red: 0.06, green: 0.06, blue: 0.06)
                    .ignoresSafeArea()
                
                VStack {
                    AppNavBar(showNetworkView: $showNetworkView).frame(height:40)
 
                    
                    ZStack {
                        MetronomeView()
                            .environmentObject(multipeerManager)
                            .environmentObject(metroVM)
                        
                        if showNetworkView {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .blur(radius: 2)
                                .onTapGesture {
                                    withAnimation { showNetworkView = false}
                                }
                            
                            SettingsView()
                                .environmentObject(networkVM)
                                .environmentObject(metroVM)
                                .frame(width: 350, height: 400)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(1)
                        }
                    }.animation(.easeInOut, value: showNetworkView)
                    
                }
                
            }
            
            
        }
    }
}




#Preview {
    ContentView()
}
