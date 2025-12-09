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
    
}


struct SoundPickerView: View {
    let availableSounds: [String]
    let selectedSound: String
    let onSelectSound: (String) -> Void

    var body: some View {
        ZStack {
            // Background: matte metal
            Color(red: 0.06, green: 0.06, blue: 0.06)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Sound Selector")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.5), radius: 8)

                // Card container
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(availableSounds, id: \.self) { sound in
                            let displayName = sound.replacingOccurrences(of: "_", with: " ")
                            let isSelected = selectedSound == sound

                            SoundRow(
                                name: displayName,
                                isSelected: isSelected
                            ) {
                                onSelectSound(sound)
                            }
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .blur(radius: 80)
                            .ignoresSafeArea()
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top, 30)
        }
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct SoundRow: View {
    let name: String
    let isSelected: Bool
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(name)
                .generalTextStyle()
                .foregroundStyle(isSelected ? .orange : .gray)
                .shadow(color: .white.opacity(isSelected ? 0.4 : 0), radius: 4)

            Spacer()

            // LED “indicator light”
            Circle()
                .fill(isSelected ? Color.orange : Color.gray.opacity(0.3))
                .frame(width: 14, height: 14)
                .shadow(color: isSelected ? .orange : .clear, radius: isSelected ? 6 : 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.red.opacity(0.1) : Color.black.opacity(isSelected ? 0.45 : 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.orange.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 1)
                        .shadow(color: isSelected ? .yellow.opacity(0.7) : .clear, radius: 8)
                )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
    }
}

struct AccentPickerView: View {
    let beatCount: Int
    let accentedBeats: Set<Int>
    let onTapBeat: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<beatCount, id: \.self) { beat in
                    Circle()
                        .fill(accentedBeats.contains(beat) ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 14, height: 14)
                        .shadow(color: accentedBeats.contains(beat) ? .orange : .clear, radius: accentedBeats.contains(beat) ? 6 : 0)
                        .onTapGesture {
                            onTapBeat(beat)
                        }
                        .padding(.trailing, ((beat + 1) % 4 == 0 && beat != beatCount - 1) ? 4 : 4)
                    if (beat + 1) % 4 == 0 && beat != beatCount - 1 {
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 2, height: 20)
                            .padding(.trailing, 4)
                    }
//                    if beat % 4 == 0 {
//                        .padding()
//                    }
                }
                    
            }
            .padding()
        }
        .frame(height:50)
        .overlay(
            Group {
                if shouldShowScrollIndicator {
                    
                    HStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.clear, Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                            .frame(width: 50)
                            .allowsHitTesting(false)
                        
                    }
                }
            }
            
                
        )
    }
    
    private var shouldShowScrollIndicator: Bool {
        
        
        let circleWidth: CGFloat = 14
        let spacing: CGFloat = 4
        let dividerWidth: CGFloat = 2
        let dividerSpacing: CGFloat = 12
        
        let dividersCount = (beatCount - 1) / 4
        let totalWidth = CGFloat(beatCount) * (circleWidth + spacing) + CGFloat(dividersCount) * (dividerWidth + dividerSpacing)
        if totalWidth > UIScreen.main.bounds.width - 40 {
            print("Scroll indicator! \(totalWidth)")
        } else {
            print("Booo. Screen width: \(UIScreen.main.bounds.width - 40)   totalWidth: \(totalWidth) "  )
        }
        return totalWidth > UIScreen.main.bounds.width - 40
            
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
                    
                    Button(action: metro.togglePlay) {
                        Text("PLAY/PAUSE")
                            .embossedLabelStyle()
                            .padding()
                            .foregroundColor(.white)
                            .background(.black)
                            .cornerRadius(10)
                    }
                    
                    Slider(
                        value: $metro.bpm,
                        in: 40...300,
                        step: stepValue ? 1 : 0.1
                    )
                    
                    .accentColor(.orange)
                    .onChange(of: metro.bpm) {
                        metro.setBPM(metro.bpm)
                    }
                    
                    Text("\(Int(metro.bpm)) BPM").mainStyle()
                    
                    Text("\(Int(metro.timeSigTop)) / \(Int(metro.timeSigBtm))").mainStyle()
                    
                    AccentPickerView(
                        beatCount: Int(metro.timeSigTop),
                        accentedBeats: metro.accentedBeats,
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
                    
                    //                let soundKeys: [String] = Array(metro.soundPairs.keys.sorted())
                    
                    
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
                    
                    Slider(
                        value: $metro.hiVolume, in: 0...5.0, step: 0.05
                    )
                    .onChange(of: metro.hiVolume) { newValue in
                        metro.setVolume(hi: Float(newValue))
                    }
                    Slider(
                        value: $metro.loVolume, in: 0...5.0, step: 0.05
                    )
                    .onChange(of: metro.loVolume) { newValue in
                        metro.setVolume(lo: Float(newValue))
                    }
                    
                    
                    HStack {
                        VStack {
                            Text("Top value").generalTextStyle().foregroundStyle(Color(.white))
                            Slider(
                                value: $metro.timeSigTop,
                                in: 1...16,
                                step: 1,
                                onEditingChanged: { isEditing in
                                    if !isEditing {
                                        metro.updateTimeSignature(top: metro.timeSigTop, bottom: metro.timeSigBtm)
                                    }}
                            )
                        }
                        
                        VStack {
                            Text("Bottom Value").generalTextStyle().foregroundStyle(Color(.white))
                            Slider(
                                value: bottomBinding,
                                in: 0...3,
                                step: 1,
                                onEditingChanged: { isEditing in
                                    if !isEditing {
                                        
                                        metro.updateTimeSignature(
                                            top: metro.timeSigTop,
                                            bottom: metro.timeSigBtm
                                        )
                                        print(metro.timeSigBtm)
                                    }
                                }
                                
                            )
                        }
                        

                        
//                        Button(action: metro.setSequence)
                    }
                    
                    
                }
                .padding()
            }
            .navigationTitle("Home")
        }
        
        
    }
    
}




#Preview {
    ContentView()
}
