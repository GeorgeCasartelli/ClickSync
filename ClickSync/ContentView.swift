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



class Metronome: ObservableObject {
    
    let sequencer = AppleSequencer()
    let sampler = MIDISampler()
    var engine : AudioEngine!
  
    @Published var bpm: Double = 120.0
    var tapTimestamps: [Double] = []
    var tapIntervals: [Double] = []
    var currentAvgBPM = 0.0
    
        
    var soundPairs: [String: (hi: String, lo: String)] = [:]
    
    @State private var selectedSoundKey: String = "Perc_Glass"
    
    @Published var availableSoundNames: [String] = []
    @Published var selectedSoundName: String = "Glass"
    @Published var spacedSoundNames: [String]!
    
    private let hiSampler = MIDISampler()  // Create a MIDI sampler unit to play notes
    private let loSampler = MIDISampler()
    
    private var hiMixer = Mixer()
    private var loMixer = Mixer()
    
    private var hiTrack: MusicTrackManager!
    private var loTrack: MusicTrackManager!
    
    @Published var timeSigTop: Double = 4;
    @Published var timeSigBtm: Double = 4;
    
    @Published var hiSamplerVolume: Double = 1.0
    @Published var loSamplerVolume: Double = 1.0
    
//    private var hiGain: Fader!
//    private var loGain: Fader!
    
    init() {
        
        engine = AudioEngine()
        soundPairs = buildSoundPairs()
        
        
        availableSoundNames = Array(soundPairs.keys).sorted()
        
        spacedSoundNames = availableSoundNames.map { $0.replacingOccurrences(of: "_", with: " ") }
//        spacedSoundNames = availableSoundNames
        print(availableSoundNames)
        selectedSoundName = availableSoundNames.first ?? ""
        
        print("Selected sound name \(selectedSoundName)")
        
        if !selectedSoundName.isEmpty {
            loadSoundPairs(named: selectedSoundName)
        } else {
            print("Selected sound name empty: \(selectedSoundName)")
        }
        
        hiMixer = Mixer(hiSampler)
        loMixer = Mixer(loSampler)
        
        // put samplers in a mixer
        let mixer = Mixer([hiMixer, loMixer])
        engine.output = mixer
        mixer.volume = 10.0
        
        initialiseSequencer()
        // Connect sequencer to sampler

        try? engine.start()  // Start AudioKit
    }
    
    func initialiseSequencer() {
        
        hiTrack = sequencer.newTrack()
        hiTrack?.setMIDIOutput(hiSampler.midiIn)
        hiTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:0), duration: Duration(beats:1))

        loTrack = sequencer.newTrack()
        loTrack?.setMIDIOutput(loSampler.midiIn)
        
        for beat in 1...3 {
            loTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:Double(beat)), duration: Duration(beats:1))
        }
        
        
        sequencer.setTempo(bpm)
        sequencer.enableLooping() // Allow short sequence to loop
    }
    

    
    func setSequence(top: Int?=nil, bottom: Int?=nil) {
        print("Values are \(top) \(bottom)")
        guard let top = top else {
            print("Returning")
            return
        }
            
        hiTrack.clear()
        loTrack.clear()
        
        
        sequencer.setLoopInfo(Duration(beats: Double(top)), loopCount: 0)
        
        hiTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:0), duration: Duration(beats:1))
//        print("Sequencer tracks array is : \(sequencer.tracks)")
        

        if top > 1 {
            for beat in 1...top-1{
                loTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats: Double(beat)), duration: Duration(beats:1))
            }
        }
        
        sequencer.rewind()
//        sequencer.setLength(Duration(beats:2))
        if top != nil {
            timeSigTop = Double(top)
        }
                
        if bottom != nil{
            timeSigBtm = Double(bottom!)
        }
                
    }
    
    func loadSoundPairs(named name: String) {
        print("Sounds to be loaded are: \(name)")
        guard let pair = soundPairs[name] else {return}
        
        print(pair.hi)
        
        try? hiSampler.loadWav("\(pair.hi)")
        try? loSampler.loadWav("\(pair.lo)")
        print("Sounds/\(pair.hi)")
    }
    
    func buildSoundPairs() -> [String: (hi: String, lo: String)] {
        var results: [String: (hi: String, lo: String)] = [:]
        
            
        let wavFiles = Bundle.main.paths(forResourcesOfType: "wav", inDirectory: nil)
            
        for file in wavFiles {
            let name = URL(fileURLWithPath: file).lastPathComponent
            let baseName = name.replacingOccurrences(of: ".wav", with: "")
            
            
            // split name into parts
            var parts = baseName.split(separator: "_")
            
            
            // get hi/lo identifier
            let lastPart = parts.last
            let type = lastPart
            
            
            // get key
            parts.removeLast()
            // create key without hi/lo identifier
            let key = parts.joined(separator: "_")

            
            // if results[key] doesn't exist, create new entry
            var entry = results[key] ?? (hi: "", lo: "")
            if type == "hi" {
                entry.hi = baseName
            } else if type == "lo" {
                entry.lo = baseName
            }
            
            results[key] = entry
            
        }
            
        return results
    }
    

    
    func soundFileUpdater() {
        
    }
    
    func startStop() {
        if sequencer.isPlaying {
            sequencer.stop()
            sequencer.rewind()
        } else {
            sequencer.play()
        }
    }
    
    func updateBPM(to newValue: Double) {
        bpm = newValue
        sequencer.setTempo(newValue)
    }
    
    func setVolume(hi: Float? = nil, lo: Float? = nil){
        
        // if there is a value in hi or lo, set the variables
        if let hi = hi { hiMixer.volume = hi }
        if let lo = lo { loMixer.volume = lo }
    }
    
    
    func tap() {
        let now = CACurrentMediaTime()
        
        tapTimestamps.append(now)
        
        
        if tapTimestamps.count > 1 {
            let prevTap = tapTimestamps[tapTimestamps.count - 2]
            let recentInterval = now - prevTap
            
            if recentInterval < 2.0 {
                
                tapIntervals.append(recentInterval)
                if tapTimestamps.count > 6 {
                    tapTimestamps.removeFirst()
                }
                if tapIntervals.count > 6 {
                    tapIntervals.removeFirst()
                }
                
                if !tapIntervals.isEmpty {
                    currentAvgBPM = 60 / (Double(tapIntervals.reduce(0, +)) / Double(tapIntervals.count))
                }
                print(String(format: "Avg BPM = %.2f", (currentAvgBPM)))
                updateBPM(to: currentAvgBPM)
            } else {
                tapTimestamps = []
                tapIntervals = []
            }

            
            print(String(format: "Now - prevTap: %.2f", now-prevTap))
            
        }
        print("tapTimeStamps: \(tapTimestamps)")
        print("tapIntervals : \(tapIntervals)")
    }
}

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
    @ObservedObject var metro: Metronome

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
                        ForEach(metro.availableSoundNames, id: \.self) { sound in
                            SoundRow(
                                name: sound.replacingOccurrences(of: "_", with: " "),
                                isSelected: metro.selectedSoundName == sound
                            )
                            .onTapGesture {
                                metro.selectedSoundName = sound
                                metro.loadSoundPairs(named: sound)
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


/// 🔊 Single selectable row styled like hardware
struct SoundRow: View {
    let name: String
    let isSelected: Bool

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
                .fill(isSelected ? Color.red.opacity(0.1) :  Color.black.opacity(isSelected ? 0.45 : 0.25) )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.orange.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 1)
                        .shadow(color: isSelected ? .yellow.opacity(0.7) : .clear, radius: 8)
                )
                
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}



struct ContentView: View {

    @StateObject var metro = Metronome()
    @State private var stepValue = false;
    
        
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06)
                        .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Metronome").mainStyle()
                    
                    Button(action: metro.startStop) {
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
                    .onChange(of: metro.bpm) { newValue in
                        metro.updateBPM(to: newValue)
                    }
                    
                    Text("\(Int(metro.bpm)) BPM").mainStyle()
                    
                    Text("\(Int(metro.timeSigTop)) / \(Int(metro.timeSigBtm))").mainStyle()
                    
                    
                    Button(action: metro.tap) {
                        Text("TAP")
                            .embossedLabelStyle()
                            .padding()
                            .foregroundColor(.white)
                            .background(.orange)
                            .cornerRadius(10)
                    }
                    
                    //                let soundKeys: [String] = Array(metro.soundPairs.keys.sorted())
                    
                    
                    NavigationLink("Select Sound") {
                        SoundPickerView(metro: metro)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(.orange)
                    .cornerRadius(10)
                    
                    Slider(
                        value: $metro.hiSamplerVolume, in: 0...5.0, step: 0.05
                    )
                    .onChange(of: metro.hiSamplerVolume) { newValue in
                        metro.setVolume(hi: Float(newValue))
                    }
                    Slider(
                        value: $metro.loSamplerVolume, in: 0...5.0, step: 0.05
                    )
                    .onChange(of: metro.loSamplerVolume) { newValue in
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
                                        metro.setSequence(top: Int(metro.timeSigTop), bottom: Int(metro.timeSigBtm))
                                    }}
                            )
                        }
                        
                        VStack {
                            Text("Bottom Value").generalTextStyle().foregroundStyle(Color(.white))
                            Slider(
                                value: $metro.timeSigBtm,
                                in: 1...16,
                                step: 1,
                                onEditingChanged: { isEditing in
                                    if !isEditing {
                                        metro.setSequence(top: Int(metro.timeSigTop), bottom: Int(metro.timeSigBtm))
                                    }}
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
