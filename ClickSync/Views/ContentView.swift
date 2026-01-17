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



struct ContentView: View {
    
    @Environment(\.horizontalSizeClass) private var hSize
    private var isPhone:Bool {hSize == .compact}
    
    @StateObject private var multipeerManager: MultipeerManager
    @StateObject private var metroVM: MetronomeView.ViewModel
    @StateObject private var networkVM: NetworkViewModel
    
    @State private var showSettingsView = false
    @State private var showSoundPickerView = false;
    @State private var showCueButtons = true;
    
    init() {
        let mpManager = MultipeerManager()
        _multipeerManager = StateObject(wrappedValue: mpManager)
        _metroVM = StateObject(wrappedValue: MetronomeView.ViewModel())
        _networkVM = StateObject(wrappedValue: NetworkViewModel(manager: mpManager))
    }
    
    var body: some View {
        //        NavigationStack {
        
        ZStack{
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()
            GeometryReader { geo in
                VStack(spacing: 0) {
                    
                    AppNavBar(showNetworkView: $showSettingsView
                    )
                    .environmentObject(multipeerManager)
                    .frame(height: isPhone ? 40 : 60)
                    //                            .padding(.top, geo.safeAreaInsets.top)
                    //                        //                    UnixTimeView()
                    //                            .foregroundStyle(.white)
                    
                    
                    ZStack {
                        MetronomeView(showCueButtons: $showCueButtons)
                            .environmentObject(multipeerManager)
                            .environmentObject(metroVM)
                            .frame(maxWidth: .infinity)
                        
                        if showSettingsView {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .blur(radius: 2)
                                .onTapGesture {
                                    withAnimation { showSettingsView = false}
                                }
                            
                            SettingsView(showSoundPickerView: $showSoundPickerView, showCueButtons: $showCueButtons, disableShowCueButtons: multipeerManager.role == .client)
                                .environmentObject(networkVM)
                                .environmentObject(metroVM)
                                .environmentObject(multipeerManager)
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
                                    metroVM.changeSound(newSound)
                                }
                                .frame(width: 340, height: 500)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(2)
                            
                        }
                    }.animation(.easeInOut, value: showSettingsView)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea())                }
            
            
            
            
        }
        .onAppear {
            metroVM.bind(multipeer: multipeerManager)
        }
    }
}




#Preview {
    ContentView()
}
