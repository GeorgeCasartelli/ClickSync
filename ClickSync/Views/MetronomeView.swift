//
//  MetronomeView.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI

struct MetronomeView: View {
    
    @EnvironmentObject var metroVM: ViewModel
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
                            .frame(width: metroVM.isPlaying ? 120 : 80,
                                   height: metroVM.isPlaying ? 120 : 80)
                            .animation(.easeOut(duration: 0.6).repeatForever(autoreverses: true), value: metroVM.isPlaying)
                        Button {
                            metroVM.togglePlay(multipeer: multipeerManager)
                        } label: {
                            
                            Text(metroVM.playIcon)
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(
                                    Circle()
                                        .fill(metroVM.playButtonColor)
                                        .shadow(radius: 4)
                                )
                                .scaleEffect(metroVM.pulseSize)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: metroVM.isPlaying)
                        }
                    }
                    
                    
                    VStack(spacing: 6) {
                        
                        BPMControl(bpm: $metroVM.bpm)
                            .padding()
                        
                        
                        VStack(spacing: 12) {
                            TimeSignaturePanel(top: $metroVM.timeSigTop, bottom: $metroVM.timeSigBtm)
                                .onChange(of: metroVM.timeSigTop) { _ in
                                    metroVM.updateTimeSignature(top: metroVM.timeSigTop, bottom: metroVM.timeSigBtm)}
                        }
                        
                        AccentPickerView(
                            beatCount: Int(metroVM.timeSigTop),
                            accentedBeats: metroVM.accentedBeats,
                            currentBeat: metroVM.currentBeat,
                            bpm: metroVM.bpm,
                            onTapBeat: { beat in
                                metroVM.toggleAccent(beat: beat)
                            }
                        )
                        
                        Button(action: metroVM.tapTempo) {
                            Text("TAP")
                                .embossedLabelStyle()
                                .padding()
                                .foregroundColor(.white)
                                .background(.orange)
                                .cornerRadius(10)
                        }
                        
                        if metroVM.showStatus {
                            Text("Start CMD @ \(metroVM.cmdReceivedTime)").foregroundStyle(.white)
                        }
                        
                        if metroVM.isPlaying {
                            Text("Now Playing @ \(metroVM.startTime)").foregroundStyle(.white)
                        }
                    }
                    
                    
                }
                .padding()
            }
        }
    }
}
