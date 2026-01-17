//
//  SettingsView.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI

struct SettingsView: View {
    
    
    @Binding var showSoundPickerView: Bool
    @Binding var showCueButtons: Bool
    
    var disableShowCueButtons: Bool

    
    @EnvironmentObject private var networkVM: NetworkViewModel
    @EnvironmentObject private var metro: MetronomeView.ViewModel
    @EnvironmentObject private var multipeerManager: MultipeerManager
    @State private var selectedTab: SettingsTab = .network
    @State private var previousTab: SettingsTab = .network
    
    
    enum SettingsTab: Int, CaseIterable, Identifiable {
        case network = 0
        case audio = 1
        case info = 2
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .network: return "Network"
            case .audio: return "Audio"
            case .info: return "Info"
            }
        }
    }
    
    private var transitionEdge: Edge {
        // for visual transition based on enum id
        selectedTab.id > previousTab.id ? .trailing : .leading
    }
    
    private var slideTransition: AnyTransition {
        .asymmetric(insertion: .move(edge: transitionEdge),
                    removal: .move(edge: transitionEdge  == .trailing ? .leading : .trailing))
    }
    
    var body: some View {
        ZStack {
            Color(.black).opacity(0.4)
            VStack(spacing: 20) {
                
                HStack(spacing: 8) {
                    
                    ForEach(SettingsView.SettingsTab.allCases) { tab in
                        Button(action: {
                            
                            previousTab = selectedTab
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.title)
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
                ZStack{
                    switch selectedTab {
                    case .network:
                        NetworkView()
                            .environmentObject(networkVM)
                            .frame(maxWidth:        .infinity,maxHeight: .infinity)
                            .cornerRadius(20)
                            .padding()
                            .transition(.opacity)
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
                                        //                                    Spacer()
                                        
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
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 8) {
                                        Button {
                                            withAnimation{
                                                showSoundPickerView = true
                                            }
                                            
                                        } label: {
                                            Text("Select Sound").generalTextStyle()
                                        }
                                        .padding()
                                        .foregroundColor(.white)
                                        .background(.orange)
                                        .cornerRadius(10)
                                        .frame(width: 180)
                                        
                                        
                                        Button {
                                            withAnimation{
                                                showCueButtons.toggle()
                                            }
                                        } label: {
                                            Text("Show Cue Buttons").generalTextStyle()
                                        }
                                        .disabled(disableShowCueButtons)
                                        .padding()
                                        .foregroundColor(disableShowCueButtons ? .gray : .white)
                                        .background(showCueButtons ? .green.opacity(0.8) : .gray.opacity(0.4))
                                        .cornerRadius(10)
                                        .frame(width: 180)
                                    }
                                    .frame(width: 200)
                                    
                                }
                            }
                            .frame(maxWidth:.infinity,maxHeight: .infinity)
                            .padding()
                            .transition(.opacity)
                        }
                        //                    .frame(maxWidth:        .infinity,maxHeight: .infinity)
                        .cornerRadius(20)
                        .padding()
                    case .info:
                        ZStack {
                            Color(.orange).opacity(0.3)
                            
                            VStack {
                                Text("This is a metronome app! Use it like a metronome!").generalTextStyle()
                            }
                        }
                        .frame(maxWidth:        .infinity,maxHeight: .infinity)
                        .cornerRadius(20)
                        .padding()
                        .transition(.opacity)
                    }
                }
                    
            }.frame(width: 350, height: 400) // box size
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
                
        }
        .onChange(of: disableShowCueButtons) { disabled in
            if disabled {
                withAnimation { showCueButtons = false }
            }
        }
        
        
    }
        
}
