import SwiftUI
import Combine

final class MetronomeViewModel: ObservableObject {
    
    @Published var bpm: Double = 120
    @Published var isPlaying: Bool = false
    @Published var selectedSoundName: String = "Glass"
    @Published var availableSoundNames: [String] = []
    
    @Published var hiVolume: Float = 1.0
    @Published var loVolume: Float = 1.0
    
    @Published var timeSigTop: Double = 4
    @Published var timeSigBtm: Double = 4

    @Published var accentedBeats: Set<Int> = [0]
    
    @Published var currentBeat: Int = 0
    
    private let engine = MetronomeEngine()
    
    init() {
        availableSoundNames = Array(engine.soundPairs.keys).sorted()

        selectedSoundName = availableSoundNames.first ?? ""
        
        engine.loadSoundPairs(named: selectedSoundName)
        
        
        engine.onBeatChange = { [weak self] beat in
            self?.currentBeat = beat
        }
    }
    
    
    
    func togglePlay() {
        isPlaying.toggle()
        engine.togglePlay()
    }
    
    func start() {
        isPlaying = true
        engine.start()
    }
    
    func stop() {
        isPlaying = false
        engine.stop()
    }
    
    func setBPM(_ newBPM: Double) {
        bpm = newBPM
        engine.setTempo(newBPM)
    }
    
    func changeSound( to name: String) {
        selectedSoundName = name
        engine.loadSoundPairs(named: name)
    }
    
    func tapTempo() {
        if let newBPM = engine.tap() {
            bpm = newBPM
        }
    }
    
    func setVolume(hi: Float? = nil, lo: Float? = nil) {
        engine.setVolume(hi: hi, lo: lo)
        hiVolume = engine.hiVolume
        loVolume = engine.loVolume
    }
    
    func updateTimeSignature(top: Double, bottom: Double) {
        
        
        let adjustedBPM = bpm / (bottom / 4.0)
        print("Top is \(top), bottom is \(bottom)")
        engine.setSequence(restart: true, top: Int(top), bottom: Int(bottom))
        if Double(engine.timeSigBtm) != bottom {
            engine.setTempo(adjustedBPM)
        }
        timeSigTop = Double(engine.timeSigTop)
        timeSigBtm = Double(engine.timeSigBtm)
        
        
    }
    
    func toggleAccent(beat: Int) {
        engine.toggleAccent(beat: beat)
        
        accentedBeats = engine.accentedBeats // update VM so UI reacts
    }
}

