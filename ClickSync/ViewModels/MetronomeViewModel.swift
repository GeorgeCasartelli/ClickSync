import SwiftUI
import Combine

extension MetronomeView {
    
    class ViewModel: ObservableObject {
        
        @Published var bpm: Double = 120 {
            didSet{ engine.setTempo(bpm)}
        }
        
        
        @Published var isPlaying: Bool = false
        @Published var selectedSoundName: String = "Glass"
        @Published var availableSoundNames: [String] = []
        
        @Published var hiVolume: Float = 1.0 {
            didSet { setVolume(hi: hiVolume, lo: loVolume)}
        }
        @Published var loVolume: Float = 1.0 {
            didSet { setVolume(hi: hiVolume, lo: loVolume)}
        }
        
        @Published var timeSigTop: Double = 4 {
            didSet {  }
        }
        @Published var timeSigBtm: Double = 4
        
        @Published var accentedBeats: Set<Int> = [0]
        @Published var currentBeat: Int = 0
        
        private var cancellables = Set<AnyCancellable>()
        
        var playIcon: String { isPlaying ? "⏸︎" : "▶︎"  }
        var playButtonColor: Color {isPlaying ? Color.orange : Color.teal.opacity(0.4)}
        var pulseSize: CGFloat { isPlaying ? 1.05 : 1.0 }
        var networkCommand: [String: String] { isPlaying ? ["action": "start", "sender": "master"] : ["action": "stop", "sender": "master"]}
        
        private let engine = MetronomeEngine()
        
        init() {
            availableSoundNames = Array(engine.soundPairs.keys).sorted()
            
            selectedSoundName = availableSoundNames.first ?? ""
            
            engine.loadSoundPairs(named: selectedSoundName)
            
            
            engine.onBeatChange = { [weak self] beat in
                self?.currentBeat = beat
            }
        }
        
      
        func togglePlay(multipeer: MultipeerManager) {
            if !isPlaying {
                // calculate the next even second for syncro start
                let now = Date().timeIntervalSince1970
                let nextEvenSecond = ceil(now) + 1.0
                let command: [String: Any] = [
                    "action": "start",
                    "sender": "master",
                    "startTime": nextEvenSecond
                ]
                print("MASTER: Sending CMD with startTime")
                multipeer.sendCommand(command)
                scheduleStart(at: nextEvenSecond) // wait to start syncro
            } else {
                isPlaying = false
                engine.stop()
                multipeer.sendCommand(["action":"stop", "sender":"master"])
            }
        }
        
        private func scheduleStart(at timestamp: Double) {
            let now = Date().timeIntervalSince1970
            let delay = timestamp - now // calculate how long till target timestamp
 
            guard delay > 0 else {
                // ensure delay is positive
                start()
                return
            }
            
            // schedule actual start
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [ weak self] in
                self?.start()
            }
        }
        func start() {
            isPlaying = true
            engine.start()
            print("Started clock at \(Date().timeIntervalSince1970)")
        }
        
        func stop() {
            isPlaying = false
            engine.stop()
        }
        
//        func setBPM(_ newBPM: Double) {
//            bpm = newBPM
//            engine.setTempo(newBPM)
//        }
        
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
//            hiVolume = engine.hiVolume
//            loVolume = engine.loVolume
        }
        
        func resetVolume() {
            hiVolume = 1.0
            loVolume = 1.0
        }
        func updateTimeSignature(top: Double? = nil, bottom: Double? = nil) {
         
            if let top = top { timeSigTop = top }
            if let bottom = bottom { timeSigBtm = bottom }
            
            var adjustedBPM = bpm
            
            if timeSigBtm == 1 {
                adjustedBPM = bpm / 4
            } else if timeSigBtm == 2 {
                adjustedBPM = bpm / 2
            } else if timeSigBtm == 4 {
                adjustedBPM = bpm
            } else if timeSigBtm == 8 {
                adjustedBPM = bpm * 2
            }
            
            engine.setSequence(restart: true, top: Int(timeSigTop))
            
            if Double(engine.timeSigBtm) != bottom {
                engine.setTempo(adjustedBPM)
            }
   
        }
        
        func toggleAccent(beat: Int) {
            engine.toggleAccent(beat: beat)
            
            accentedBeats = engine.accentedBeats // update VM so UI reacts
        }
        
        func bind(multipeer: MultipeerManager) {
            print("BIND: Setting subs")
            multipeer.$lastCommand
                .sink { [weak self] optionalCommand in
                    print("SINK: Received the following: \(String(describing: optionalCommand))")
                    guard let command = optionalCommand else { return }
                    guard let action = command["action"] as? String else {return}
                    self?.handleRemoteAction(action, role: multipeer.role, command: command)
                }
                .store(in: &cancellables)
        }
        
        func handleRemoteAction(_ action: String, role: DeviceRole, command: [String: Any]) {
            print("Handle remoe Action: Action: \(action), Role: \(role), command: \(command)")
            guard role == .client else {
                print("Not client, returning")
                return
            } // only follow if client
            
            switch action {
            case "start":
                if let startTime = command["startTime"] as? Double {
                    scheduleStart(at: startTime)
                }
            case "stop":
                stop()
            default: break
            }
        }
    }
    
}
