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
    
    private let hiSampler = MIDISampler()  // Create a MIDI sampler unit to play notes
    private let loSampler = MIDISampler()
    
    init() {
        
        engine = AudioEngine()
//        soundFileLibraryGenerator()
        soundPairs = buildSoundPairs()
        
        
        availableSoundNames = Array(soundPairs.keys).sorted()
        
        let replacedArray = availableSoundNames.map { $0.replacingOccurrences(of: "_", with: " ") }
        
        for names in replacedArray  {
            print(names)
        }
        
        selectedSoundName = availableSoundNames.first ?? ""
        
        print("Selected sound name \(selectedSoundName)")
        
        if !selectedSoundName.isEmpty {
            loadSoundPairs(named: selectedSoundName)
        } else {
            print("Selected sound name empty: \(selectedSoundName)")
        }
        
        
        engine.output = Mixer([hiSampler, loSampler])             // Connect reverb to audio output


        let hiTrack = sequencer.newTrack()
        hiTrack?.setMIDIOutput(hiSampler.midiIn)
        hiTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:0), duration: Duration(beats:1))

        let loTrack = sequencer.newTrack()
        loTrack?.setMIDIOutput(loSampler.midiIn)
        
        for beat in 1...3 {
            loTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:Double(beat)), duration: Duration(beats:1))
        }
        
        
        sequencer.setTempo(bpm)
        sequencer.enableLooping() // Allow short sequence to loop
        // Connect sequencer to sampler

        try? engine.start()  // Start AudioKit
        sequencer.play()    // then the sequencer
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


struct ContentView: View {

    @StateObject var metro = Metronome()
    @State private var stepValue = false;
    
        
    var body: some View {
        ZStack {
            VStack {
                Text("Metronome")
                
                Button(action: metro.startStop) {
                    Text("Play/Pause")
                        .padding()
                        .foregroundColor(.white)
                        .background(.orange)
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
                
                Text("\(metro.bpm, specifier: "%.1f") BPM")
                
                Toggle(isOn: $stepValue) {
                    Text("Fine or Course")
                }
                HStack{
                    ForEach([100,120,150,200], id: \.self) { preset in
                        Button("\(preset)") {
                            metro.updateBPM(to: Double(preset))
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                
                Button(action: metro.tap) {
                    Text("Tap")
                        .padding()
                        .foregroundColor(.white)
                        .background(.orange)
                        .cornerRadius(10)
                }
                
//                let soundKeys: [String] = Array(metro.soundPairs.keys.sorted())
                
                Picker("Sound", selection: $metro.selectedSoundName) {
                    ForEach(metro.availableSoundNames, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: metro.selectedSoundName) { newValue in
                    metro.loadSoundPairs(named: newValue)
                    
                    print("Should have changed to \(newValue)")
                }
            }
            
            
        }
    }
    
}




#Preview {
    ContentView()
}
