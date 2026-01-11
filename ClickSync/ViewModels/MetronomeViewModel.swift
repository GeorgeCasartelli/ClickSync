import SwiftUI
import Combine

extension MetronomeView {
    
    class ViewModel: ObservableObject {
        
        @Published var bpm: Double = 120 {
            didSet{ engine.setTempo(bpm)}
        }
        
        @Published var currentSequencerPosition: Double = 0
        
        @Published var showStatus: Bool = false;
        @Published var startTime: Double = 0.0
        @Published var cmdReceivedTime: Double = 0.0
        
        
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
        
        private var runID = UUID() // runtime ID
        
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
//                start()
            } else {
                isPlaying = false
                engine.stopTransport()
                multipeer.sendCommand(["action":"stop", "sender":"master"])
            }
        }
        
        
        
        private func scheduleStart(at timestamp: Double) {
            let myRun = runID
            
            let now = Date().timeIntervalSince1970
            let warmup = 0.25
            
            let warmupDelay = (timestamp - warmup) - now
            let delay = timestamp - now // calculate how long till target timestamp
 
            
            if warmupDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + warmupDelay) { [weak self] in
                    
                    guard let self = self else { return } // avoid individual unconditionals for following
                    guard self.runID == myRun else {return }
                    self.engine.setMuted(true)
                    self.engine.prepareTransport()
                }
            } else {
                guard runID == myRun else { return }
                engine.setMuted(true);
                engine.prepareTransport()
            }
            
            if delay > 0 {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [ weak self ] in
                    guard let self = self else { return }
                    guard self.runID == myRun else {return }
                    
                    guard let startHost = self.engine.hostTimeForUnixTimestamp(timestamp) else { return}
                    self.engine.playTransport(atHostTime: startHost)
                    
                    self.engine.setMuted(false)
                    self.isPlaying = true;
                    self.startTime = Date().timeIntervalSince1970
                }
            } else {
                guard runID == myRun else { return }
                
                guard let startHost = engine.hostTimeForUnixTimestamp(timestamp) else { return }
                engine.startTransportFromtZero()
                engine.setMuted(false)
                isPlaying = true
                startTime = Date().timeIntervalSince1970
            }
                // ensure delay is positive

        }
            
            // schedule actual start

        
        func start() {
            isPlaying = true
            if let startHost = engine.hostTimeForUnixTimestamp(startTime) {
                engine.playTransport(atHostTime: startHost)
            }

//            startPositionUpdates()
            startTime = Date().timeIntervalSince1970
            print("Started clock at \(startTime)")
        }
        
        func stop() {
            runID = UUID()
            isPlaying = false
            engine.stopTransport()
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
//                    start()
                    showStatus = true;
                    cmdReceivedTime = Date().timeIntervalSince1970
                }
            case "stop":
                stop()
                showStatus = false;
            default: break
            }
        }
    }
    
}
