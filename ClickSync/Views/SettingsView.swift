//
//  SettingsView.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject private var networkVM: NetworkViewModel
    @EnvironmentObject private var metro: MetronomeView.ViewModel
    @State private var selectedTab: SettingsTab = .network
    
    
    
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case network = "Network"
        case audio = "Audio"
        case info = "Info"
        var id: String { rawValue }
    }
    
    
    var body: some View {
        ZStack {
            Color(.black).opacity(0.4)
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(SettingsView.SettingsTab.allCases) { tab in
                        Button(action: { selectedTab = tab }) {
                            Text(tab.rawValue)
                                .generalTextStyle()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    selectedTab == tab ? Color.orange.opacity(0.8) : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                
//                Divider()
                
                switch selectedTab {
                case .network:
                    NetworkView()
                        .environmentObject(networkVM)
                        .frame(maxWidth:        .infinity,maxHeight: .infinity)
                        .cornerRadius(20)
                        .padding()
                case .audio:
                    ZStack{
                        Color(.orange).opacity(0.3)
                        VStack {
                            Text("Adjust metronome volumes:").generalTextStyle()
                            Spacer()
                            HStack{
                                VStack{
                                    HStack(spacing:16) {
                                        VolumeBar(label: "HI", value: $metro.hiVolume, color: .orange)
                                        VolumeBar(label: "LO", value: $metro.loVolume, color: .orange)
                                    }
                                    Spacer()
                                    
                                    Button{
                                        withAnimation{
                                            metro.resetVolume()
                                        }
                                    } label: {
                                        Text("Reset").generalTextStyle()
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(.orange)
                                    .cornerRadius(10)
                                }
                                .padding()
                                NavigationLink {
                                    SoundPickerView(
                                        availableSounds: metro.availableSoundNames, selectedSound: metro.selectedSoundName) { newSound in
                                            metro.changeSound(to: newSound)
                                        }
                                } label: {
                                    Text("Select Sound").generalTextStyle()
                                }
                                .padding()
                                .foregroundColor(.white)
                                .background(.orange)
                                .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth:.infinity,maxHeight: .infinity)
                        .padding()
                    }
                    .frame(maxWidth:        .infinity,maxHeight: .infinity)
                    .cornerRadius(20)
                    .padding()
                case .info:
                    VStack {
                        Text("This is a metronome app! Use it like a metronome!").generalTextStyle()
                    }
                    .frame(maxWidth:        .infinity,maxHeight: .infinity)
                    .padding()
                }
            }.frame(width: 350, height: 400) // box size
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
                
        }
        
    }
}
