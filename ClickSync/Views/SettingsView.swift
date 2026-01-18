//
//  SettingsView.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI


/// Settings only modal with tabbed sections for network/audio/info
///
/// UI only
struct SettingsView: View {
    
    
    @Binding var showSoundPickerView: Bool
    @Binding var showCueButtons: Bool
    
    var disableShowCueButtons: Bool

    
    @EnvironmentObject private var networkVM: NetworkViewModel
    @EnvironmentObject private var metro: MetronomeViewModel
    @State private var selectedTab: SettingsTab = .network
    @State private var previousTab: SettingsTab = .network
    
    // MARK:  - TABS
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
    
    // MARK: - VIEW
    var body: some View {
        ZStack {
            Color(.black).opacity(0.4)
            VStack(spacing: 20) {
                
                HStack(spacing: 8) {
                    //settings tabs
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
                
                ZStack{
                    // display relevant info for each tab
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
                                        
                                        Button(action: metro.tapTempo) {
                                            Text("Tap Tempo")
                                                .generalTextStyle()
                                                .padding()
                                                .foregroundColor(.white)
                                                .background(.orange)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .frame(width: 180)
                                    
                                }
                            }
                            .padding()
                            
                        }
                        //                    .frame(maxWidth:        .infinity,maxHeight: .infinity)
                        
                        .frame(maxWidth:.infinity,maxHeight: .infinity)
                        .cornerRadius(20)
                        .padding()
                        .transition(.opacity)
                    case .info:
                        ZStack {
                            Color(.orange).opacity(0.3)

                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("ClickSync")
                                        .mainStyle()

                                    Text("A networked metronome for rehearsals and live use. One device can act as the Master and keep other devices locked in time.")
                                        .generalTextStyle()
                                        .foregroundColor(.white.opacity(0.9))

                                    Text("Quick guide")
                                        .generalTextStyle()
                                        .foregroundColor(.white)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("• Network: Open the Network tab and choose a role.")
                                            .generalTextStyle()
                                        Text("• Master Device: Starts/stops playback and broadcasts tempo changes.")
                                            .generalTextStyle()
                                        Text("• Client Device: Receives commands and follows the Master automatically.")
                                            .generalTextStyle()
                                        Text("• Tempo Cues: Tap a cue to queue a BPM change at the next bar boundary.")
                                            .generalTextStyle()
                                        Text("• Accents: Tap beats in the accent row to toggle accented clicks.")
                                            .generalTextStyle()
                                        Text("• Audio: Adjust HI/LO volumes and choose click sounds in the Audio tab.")
                                            .generalTextStyle()
                                    }
                                    .foregroundColor(.white.opacity(0.9))

                                    Divider().opacity(0.25)

                                    Text("Tip: For best sync, connect devices before starting playback and keep one Master.")
                                        .generalTextStyle()
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        // MARK: - State constraints
        .onChange(of: disableShowCueButtons) { disabled in
            if disabled {
                withAnimation { showCueButtons = false }
            }
        }
        
        
    }
        
}
