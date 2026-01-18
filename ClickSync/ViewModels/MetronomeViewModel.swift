import SwiftUI
import Combine


class MetronomeViewModel: ObservableObject {
    
    // MARK: - Published UI State
    @Published var bpm: Double = 120 {
        didSet{
            engine.setTempo(bpm)
        }
    }
    
    // tempo cues
    @Published var tempoCues: [TempoCue] = [
        TempoCue(label: "Slow", bpm: 90),
        TempoCue(label: "Mid", bpm: 110),
        TempoCue(label: "Base", bpm: 120),
        TempoCue(label: "Fast", bpm: 180)
    ]
    
    @Published var queuedCueID: UUID? = nil
    
    @Published var pendingBpm: Double? = nil
    @Published var queueBpmEnabled: Bool = true
    
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
    
    @Published var timeSigTop: Double = 4
    @Published var timeSigBtm: Double = 4
    
    @Published var accentedBeats: Set<Int> = [0]
    @Published var currentBeat: Int = 0
    
    // MARK: - Internal State Dependencies
    private var cancellables = Set<AnyCancellable>()
    
    var playIcon: String { isPlaying ? "⏸︎" : "▶︎"  }
    var playButtonColor: Color {isPlaying ? Color.orange : Color.teal.opacity(0.4)}
    var pulseSize: CGFloat { isPlaying ? 1.2 : 1.0 }
    
    private let engine = MetronomeEngine()
    
    private var runID = UUID() // runtime ID
    
    private let cueStore = TempoCueStore()
    
    enum TempoChangeMode {
        case immediate
        case queued
    }
    
    // MARK: - Initialisation
    init() {
        availableSoundNames = Array(engine.soundPairs.keys).sorted()
        
        selectedSoundName = availableSoundNames.first ?? ""
        
        engine.loadSoundPairs(named: selectedSoundName)
        
        if let saved = cueStore.load() {
            tempoCues = saved
        }
        
        $tempoCues
            .dropFirst()
            .sink  { [ weak self] cues in
                self?.cueStore.save(cues)
            }
            .store(in: &cancellables)
        
        engine.onBeatChange = { [weak self] beat in
            guard let self else { return }
            self.currentBeat = beat
            
            if beat == Int(timeSigTop)-1, let queued = self.pendingBpm {
                self.applyTempo(queued)
            }
        }
        
        
    }
    
    // MARK: - UI Intent (called from views)
    
    func triggerTempoCueFromUI(_ cue: TempoCue) {
        requestTempoChange(cue.bpm, mode: .queued)
        queuedCueID = cue.id
        
        broadcast(NetworkCommand(action: .cueBPM, sender: .master, bpm: bpm))
    }
       
    
    
    // if running offline start immediately
    // if master with connected peers, schedule start time and broadcast
    // clients dont initiate network transport, they follow master cmds
    func togglePlayFromUI() {
    
        if !isPlaying {
            
            guard let multipeer else {
                start()
                return
            }
            
            guard multipeer.role == .master else {
                start()
                return
            }
            
            guard !multipeer.connectedPeers.isEmpty else {
                start()
                return
            }
            
            let now = Date().timeIntervalSince1970
            let nextEvenSecond = ceil(now) + 1.0
            
            broadcast(NetworkCommand(action: .start, sender: .master, startTime: nextEvenSecond))
            
            scheduleStart(at: nextEvenSecond)
        } else {
            stop()
            broadcast(NetworkCommand(action: .stop, sender: .master))

        }
    }

    // MARK: - Transport Scheduling
    
    func start() {
        isPlaying = true
        engine.startTransportFromtZero()
        startTime = Date().timeIntervalSince1970
        print("Started clock at \(startTime)")
    }
    
    func stop() {
        runID = UUID()
        isPlaying = false
        engine.stopTransport()
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

    }

    
    
    // MARK: - Tempo Logic
    
    func requestTempoChange(_ newBpm: Double, mode: TempoChangeMode = .immediate) {
        switch mode {
        case .immediate:
            applyTempo(newBpm)
        case .queued:
            if isPlaying && queueBpmEnabled {
                pendingBpm = newBpm
            } else {
                applyTempo(newBpm)
            }
        }
    }
    
    private func applyTempo(_ bpm: Double) {
        self.bpm = bpm
        pendingBpm = nil
        queuedCueID = nil
    }
    
    func updateCue(_ updated: TempoCue) {
        if let i = tempoCues.firstIndex(where: { $0.id == updated.id }) {
            tempoCues[i] = updated
        }
    }
    
    func setBpmFromUI(_ bpm: Double) {
        requestTempoChange(bpm, mode: .immediate)
        broadcast(NetworkCommand(action:.setBPM, sender:.master, bpm: bpm))
    }

    
    // MARK: - Sound and volume
    
    func changeSound(_ name: String) {
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
    
    // MARK: - Time sig & Accents
    func updateTimeSignature(top: Double? = nil, bottom: Double? = nil) {
        
        // start of subdivision logic
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
    
    // MARK: - Networking
    private weak var multipeer: MultipeerManager?
    private var didBind = false
    
    // helper to avoid repeated code
    private func broadcast(_ cmd: NetworkCommand) {
        guard let multipeer,
              multipeer.role == .master,
              !multipeer.connectedPeers.isEmpty else { return }
        multipeer.sendCommand(cmd)
    }
    
    func attach(multipeer: MultipeerManager) {
        self.multipeer = multipeer
        guard !didBind else {return}
        bind(multipeer: multipeer)
        didBind = true
    }
    
    
    
    func bind(multipeer: MultipeerManager) {
        print("BIND: Setting subs")
        multipeer.$lastCommand
            .compactMap { $0 }
            .sink { [weak self] command in
                print("SINK: Received the following: \(String(describing: command))")
                self?.handleRemoteAction(command, role: multipeer.role)
            }
            .store(in: &cancellables)
    }
    // MARK: - Remote Cmd Handling
    func handleRemoteAction(_ command: NetworkCommand, role: DeviceRole) {
        print("Handle remome command: command: \(command), Role: \(role)")
        guard role == .client else { return } // only follow if client
        switch command.action {
        case .start:
            guard let startTime = command.startTime else { return }
                scheduleStart(at: startTime)
                //                    start()
                showStatus = true;
                cmdReceivedTime = Date().timeIntervalSince1970
            
        case .stop:
            stop()
            showStatus = false;
        
            
        case .setBPM:
            guard let tempo = command.bpm else { return }
            requestTempoChange(tempo, mode: .immediate)
            
            
        case .cueBPM:
            guard let tempo = command.bpm else { return }
            requestTempoChange(tempo, mode: .queued)
            
        }
    }
}


