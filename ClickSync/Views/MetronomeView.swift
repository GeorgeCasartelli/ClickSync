//
//  MetronomeView.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI

struct MetronomeView: View {
    
    @EnvironmentObject var metro: ViewModel
    @EnvironmentObject private var multipeerManager:  MultipeerManager


    let bottomValues = [1.0, 2.0, 4.0, 8.0]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    
                    ZStack{
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: metro.isPlaying ? 120 : 80,
                                   height: metro.isPlaying ? 120 : 80)
                            .animation(.easeOut(duration: 0.6).repeatForever(autoreverses: true), value: metro.isPlaying)
                        Button {
                            metro.togglePlay(multipeer: multipeerManager)
                        } label: {
                            
                            Text(metro.playIcon)
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(
                                    Circle()
                                        .fill(metro.playButtonColor)
                                        .shadow(radius: 4)
                                )
                                .scaleEffect(metro.pulseSize)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: metro.isPlaying)
                        }
                    }
                    
                    
                    VStack(spacing: 6) {
                        
                        BPMControl(bpm: $metro.bpm)
                            .padding()
                        
                        
                        VStack(spacing: 12) {
                            TimeSignaturePanel(top: $metro.timeSigTop, bottom: $metro.timeSigBtm)
                                .onChange(of: metro.timeSigTop) { _ in
                                    metro.updateTimeSignature(top: metro.timeSigTop, bottom: metro.timeSigBtm)}
                        }
                        
                        AccentPickerView(
                            beatCount: Int(metro.timeSigTop),
                            accentedBeats: metro.accentedBeats,
                            currentBeat: metro.currentBeat,
                            bpm: metro.bpm,
                            onTapBeat: { beat in
                                metro.toggleAccent(beat: beat)
                            }
                        )
                        
                        Button(action: metro.tapTempo) {
                            Text("TAP")
                                .embossedLabelStyle()
                                .padding()
                                .foregroundColor(.white)
                                .background(.orange)
                                .cornerRadius(10)
                        }
                                             
                    }
                    
                    
                }
                .padding()
            }.onChange(of: multipeerManager.lastAction) { action in
                guard let action = action else { return }
                
                metro.handleRemoteAction(action, role: multipeerManager.role)
            }
        }
    }
}
