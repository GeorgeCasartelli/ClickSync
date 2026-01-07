//
//  MetronomeEngine.swift
//  ClickSync
//
//  Created by George Casartelli on 04/12/2025.
//

import AudioKit
import AVFoundation
import Foundation

class MetronomeEngine {
    let engine = AudioEngine()
    	
    private let hiSampler = MIDISampler()
    private let loSampler = MIDISampler()
    
    private var hiMixer: Mixer!
    private var loMixer: Mixer!
    
    let sequencer = AppleSequencer()
    
    private var hiTrack: MusicTrackManager!
    private var loTrack: MusicTrackManager!
    
    private(set) var hiVolume: Float = 1.0
    private(set) var loVolume: Float = 1.0
    
    private var tapTimestamps: [Double] = []
    private var tapIntervals: [Double] = []
    private(set) var currentAvgBPM: Double = 120
    
    private(set) var timeSigTop: Int = 4;
    private(set) var timeSigBtm: Int = 4;
    
    private(set) var soundPairs: [String: (hi: String, lo: String)] = [:]
    private(set) var accentedBeats: Set<Int> = [0]
    private(set) var currentBeat: Int = 0
    
    private var displayLink: CADisplayLink?
    
    var onBeatChange: ((Int) -> Void)?
    init() {
        soundPairs = buildSoundPairs()
        
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
    
    private func initialiseSequencer() {
        
        hiTrack = sequencer.newTrack()
        hiTrack?.setMIDIOutput(hiSampler.midiIn)
        hiTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:0), duration: Duration(beats:1))

        loTrack = sequencer.newTrack()
        loTrack?.setMIDIOutput(loSampler.midiIn)
        
        for beat in 1...3 {
            loTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats:Double(beat)), duration: Duration(beats:1))
        }
        
        
        sequencer.setTempo(120)
        sequencer.enableLooping() // Allow short sequence to loop
    }
    
    func setSequence(restart: Bool = false, top: Int) {

//        accentedBeats = accentedBeats.filter { $0 < top }
        
        if accentedBeats.isEmpty {
            accentedBeats.insert(0)
        }
        
        hiTrack.clear()
        loTrack.clear()
        
        sequencer.setLoopInfo(Duration(beats: Double(top)), loopCount: 0)

        for beat in 0..<top {
            if accentedBeats.contains(beat) {
                hiTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats: Double(beat)), duration: Duration(beats: 1))
            } else {
                loTrack?.add(noteNumber: 60, velocity: 127, position: Duration(beats: Double(beat)), duration: Duration(beats: 1))
            }
        }
        if restart {
            sequencer.rewind()
        }

        timeSigTop = top
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
    
    
    func start() {
        sequencer.play()
        startBeatTracking()
    }
    
    func stop() {
        sequencer.stop()
        sequencer.rewind()
        displayLink?.invalidate()
        currentBeat = 0
    }
    
    private func startBeatTracking() {
        displayLink?.invalidate()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateBeat))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateBeat() {
        let position = sequencer.currentPosition.beats
        let newBeat = Int(position) % timeSigTop
        
        if newBeat != currentBeat {
            currentBeat = newBeat
            print("\(currentBeat + 1)")
            
            DispatchQueue.main.async{ [weak self] in
                self?.onBeatChange?(newBeat)
            }
        }
    }
    
    func togglePlay() {
        sequencer.isPlaying ? stop() : start()
    }
    
    func setTempo(_ bpm: Double) {
        sequencer.setTempo(bpm)

    }
    
    func setVolume(hi: Float? = nil, lo: Float? = nil){
        // if there is a value in hi or lo, set the variables
        if let hi = hi {
            hiMixer.volume = hi
            hiVolume = hi
        }
        if let lo = lo {
            loMixer.volume = lo
            loVolume = lo
        }
    }
    
    func tap() -> Double? {
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

                    let avg = 60 / (Double(tapIntervals.reduce(0, +)) / Double(tapIntervals.count))
                currentAvgBPM = avg
                setTempo(avg)
                return avg
            } else {
                tapTimestamps = []
                tapIntervals = []
            }

            
            print(String(format: "Now - prevTap: %.2f", now-prevTap))
            
        }
        print("tapTimeStamps: \(tapTimestamps)")
        print("tapIntervals : \(tapIntervals)")
        return nil
    }
    
    func toggleAccent(beat: Int) {
        if accentedBeats.contains(beat) {
            accentedBeats.remove(beat)
        } else {
            accentedBeats.insert(beat)
        }
        setSequence(restart: false, top: timeSigTop);
    }
}
