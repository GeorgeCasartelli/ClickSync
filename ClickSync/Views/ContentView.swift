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

struct UnixTimeView: View {
    @State private var unixTime: TimeInterval = Date().timeIntervalSince1970

    // 60 Hz update feels “alive” but you can lower this if you want
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(String(format: "%.3f", unixTime))
            .font(.system(size: 24, weight: .medium, design: .monospaced))
            .onReceive(timer) { _ in
                unixTime = Date().timeIntervalSince1970
            }
    }
}

struct ContentView: View {
    @StateObject private var multipeerManager: MultipeerManager
    @StateObject private var metroVM: MetronomeView.ViewModel
    @StateObject private var networkVM: NetworkViewModel
    
    @State private var showNetworkView = false
    @State private var showSoundPickerView = false;
    
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
 
//                    UnixTimeView()
                        .foregroundStyle(.white)
                    Spacer()
                    
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
                            
                            SettingsView(showSoundPickerView: $showSoundPickerView)
                                .environmentObject(networkVM)
                                .environmentObject(metroVM)

                                .frame(width: 350, height: 400)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(1)
                        }
                        
                        if showSoundPickerView {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .blur(radius: 2)
                                .onTapGesture {
                                    withAnimation { showSoundPickerView = false}
                                }
                            
                            SoundPickerView(
                                availableSounds: metroVM.availableSoundNames, selectedSound: metroVM.selectedSoundName) { newSound in
                                    metroVM.changeSound(to: newSound)
                                }
                                .frame(width: 340, height: 500)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(2)
                            
                        }
                    }.animation(.easeInOut, value: showNetworkView)
                    
                }
                
            }
            
            
        }
        .onAppear {
            metroVM.bind(multipeer: multipeerManager)
        }
    }
}




#Preview {
    ContentView()
}
