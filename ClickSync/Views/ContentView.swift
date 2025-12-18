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

    var body: some View {
        VStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))

            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(height: CGFloat(value / 5.0) * 120),
                    alignment: .bottom
                )
                .frame(width: 36, height: 120)
        }
    }
}



struct ContentView: View {
    
    @StateObject var metro = MetronomeViewModel()
    @State private var stepValue = false;
    
    let bottomValues = [1.0, 2.0, 4.0, 8.0]
    @State private var bottomIndex: Double = 1
    
    var bottomBinding: Binding<Double> {
        Binding(
            get: {
                // Convert actual bottom value → index
                log2(metro.timeSigBtm)
            },
            set: { newIndex in
                // Update actual model in real-time
                metro.timeSigBtm = pow(2, newIndex)
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Metronome").mainStyle()
                    
                    ZStack{
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: metro.isPlaying ? 120 : 80,
                                   height: metro.isPlaying ? 120 : 80)
                            .animation(.easeOut(duration: 0.6).repeatForever(autoreverses: true), value: metro.isPlaying)
                        Button(action: metro.togglePlay) {
                            Text(metro.isPlaying ? "⏸︎" : "▶︎")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(
                                    Circle()
                                        .fill(metro.isPlaying ? Color.orange : Color.teal.opacity(0.4))
                                        .shadow(radius: 4)
                                )
                                .scaleEffect(metro.isPlaying ? 1.05 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: metro.isPlaying)
                        }
                    }
                    
                    
                    VStack(spacing: 6) {
                        
                        BPMControl(bpm: $metro.bpm)
                            .onChange(of: metro.bpm) { newValue in
                                metro.setBPM(newValue)
                            }.padding()
                        
                        
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
                        
                        NavigationLink("Select Sound") {
                            SoundPickerView(
                                availableSounds: metro.availableSoundNames, selectedSound: metro.selectedSoundName) { newSound in
                                    metro.changeSound(to: newSound)
                                }
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(.orange)
                        .cornerRadius(10)
                        
                        //                    Slider(
                        //                        value: $metro.hiVolume, in: 0...5.0, step: 0.05
                        //                    )
                        //                    .onChange(of: metro.hiVolume) { newValue in
                        //                        metro.setVolume(hi: Float(newValue))
                        //                    }
                        //                    Slider(
                        //                        value: $metro.loVolume, in: 0...5.0, step: 0.05
                        //                    )
                        //                    .onChange(of: metro.loVolume) { newValue in
                        //                        metro.setVolume(lo: Float(newValue))
                        //                    }
                        //                    HStack(spacing:40) {
                        //                        HStack(spacing: 16) {
                        //                            VolumeBar(label: "HI", value: $metro.hiVolume, color: .orange)
                        //                            VolumeBar(label: "LO", value: $metro.loVolume, color: .orange)
                        //                                .padding()
                        //
                        //                        }
                        //                    }
                        
                        //                        Button(action: metro.setSequence)
                    }
                    
                    
                }
                .padding()
            }
            .navigationTitle("Home")
            //            .navigationBarTitleDisplayMode(.inline)
            //            .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.06), for: .navigationBar)
            //            .toolbarBackground(.visible, for: .navigationBar)
            
        }
        
        
    }
    
}




#Preview {
    ContentView()
}
