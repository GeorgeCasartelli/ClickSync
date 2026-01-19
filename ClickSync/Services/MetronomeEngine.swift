//
//  MetronomeEngine.swift
//  ClickSync
//
//  Created by George Casartelli on 04/12/2025.
//

//MARK: METRONOME ENGINE
///MetronomeEnging is a service tht encapsulaates AudioKit + deterministic tick scheduling
///ViewModels control/interract with engine through small API (tempo, transport, accents etc) and UI updates delivered thru callbacks
///
/// Instead of using AppleSequencer we use hostTime scheduling.
/// Thiis makes tighter synchro between multiple devices

import AudioKit
import AVFoundation
import Foundation

class MetronomeEngine {
    let engine = AudioEngine()
    	
    private let hiSampler = MIDISampler()
    private let loSampler = MIDISampler()
    
    private var hiMixer: Mixer!
    private var loMixer: Mixer!
    private var mainMixer: Mixer!
    
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
    
    var onBeatChange: ((Int) -> Void)?
    
    ///   VARIABLES FOR SEQUENCER:
    private var tickTimer: DispatchSourceTimer?
    private var nextTickHostTime: UInt64 = 0
    private var tickPeriodSeconds: Double = 0
    private let tickLookahead: Double = 0.10     // schedule 100ms ahead
    private let tickInterval: Double = 0.02      // reschedule every 20ms
    private var startHostTime: UInt64 = 0
    private var beatIndex: Int = 0
    
    private var transportRunID = UUID()
    private var isTransportRunning = false


    private(set) var tempo: Double = 120
    
    private var session: AVAudioSession { AVAudioSession.sharedInstance() }
    init() {
        
        soundPairs = buildSoundPairs()
        
        hiMixer = Mixer(hiSampler)
        loMixer = Mixer(loSampler)
        
        // put samplers in a mixer
        mainMixer = Mixer([hiMixer, loMixer])
        engine.output = mainMixer
        mainMixer.volume = 10.0
        
        configureAudioSession()
        
        try? engine.start()  // Start AudioKit
    }
    
    
//MARK: Audio session config
    private func configureAudioSession() {
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            // starting w low buffer, 256 frames *48k is 5.3ms
            try session.setPreferredIOBufferDuration(0.005);
            try session.setActive(true)
            print("Audio session: samplerate = \(session.sampleRate), buf=\(session.ioBufferDuration), outLatency=\(session.outputLatency)")
        } catch {
            print("Audio session config error: \(error)")
        }
    }
    
    /// converting from seconds to hostTime and baack
    private func secondsToHostTime(_ seconds: Double) -> UInt64 {
        return AVAudioTime.hostTime(forSeconds: seconds)
    }
    
    private func hostTimeToSeconds(_ hostTime: UInt64) -> Double{
        return AVAudioTime.seconds(forHostTime: hostTime)
    }
    
    private func currentHostTime() -> UInt64? {
        engine.avEngine.outputNode.lastRenderTime?.hostTime
    }
    
    private func updateTickPeriod() {
        // quaver beats in seaconds
        tickPeriodSeconds = 60.0 / Double(tempo)
        print("tick period updated to \(tickPeriodSeconds), bpm: \(tempo)")
    }
    
    
    func setMuted(_ muted: Bool) {
        mainMixer.volume = muted ? 0.0 : 8.0
    }
    
   // update sequence (accent change or timesig change)
    func setSequence(restart: Bool = false, top: Int) {

        accentedBeats = accentedBeats.filter { $0 < top }
        
        if accentedBeats.isEmpty {
            accentedBeats.insert(0)
        }

        timeSigTop = top
        
        if isTransportRunning {
            
            if restart, let newHost = currentHostTime() {
                playTransport(atHostTime: newHost)
            }
        }
    }

    // load/build different sounds.
    // all sounds found on reddit from u/errorjones https://www.reddit.com/r/audioengineering/comments/kg8gth/free_click_track_sound_archive/
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

        // if "lo" with no "hi", mirror across
        for (key, entry) in results {
            var e = entry
            if e.hi.isEmpty { e.hi = e.lo }
            if e.lo.isEmpty { e.lo = e.hi }
            results[key] = e
        }
            
        return results
    }
    
    func prepareTransport() {
        // deprecated
    }
    
    func startTransportFromtZero() {
        guard let nowHost = currentHostTime() else { return }
        playTransport(atHostTime: nowHost)
    }
    
    //MARK: Sequencer Scheduling
    func playTransport(atHostTime hostTime: UInt64) {
        stopTransport()
        
        transportRunID = UUID() // create new UUID for runtime validation
        isTransportRunning = true
        
        updateTickPeriod() 
        startHostTime = hostTime
        nextTickHostTime = hostTime
        beatIndex = 0
        currentBeat = 0
        
        DispatchQueue.main.async { [weak self] in
            self?.onBeatChange?(0)
        }
        // start the playback
        startTickScheduler()
    }
    
    func stopTransport() {
        
        // create new UUID for stop, invalidate previous runTime
        transportRunID = UUID()
        isTransportRunning = false
        
        tickTimer?.cancel()
        tickTimer = nil
        
        currentBeat = 0
        beatIndex = 0
        
        DispatchQueue.main.async { [ weak self ] in
            self?.onBeatChange?(0)
        }
    }

    // maintenance timer to trigger scheduleTicksLookahead a bunch of times per sencond
    private func startTickScheduler() {
        // dispatch source time on high prio q
        let timer = DispatchSource.makeTimerSource(queue:  DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: tickInterval)

        // fire every 20ms
        timer.setEventHandler { [weak self] in
            guard let self else {return}
            self.scheduleTicksLookahead()
        }
        
        tickTimer = timer
        timer.resume()
    }

    // schedule beats within a short lookahead window to reduce jitter
    private func scheduleTicksLookahead() {
        // read current monotonic audio host time
        guard let nowHost = currentHostTime() else { return }
        // find end of lookahead window in hosttime units
        let lookaheadHost = nowHost &+ secondsToHostTime(tickLookahead)
        // schedule beats until lookahead full
        while nextTickHostTime <= lookaheadHost {
            // check accents and call hi/lo (determine beat index(
            let beat = beatIndex % timeSigTop
            let isAccented = accentedBeats.contains(beat)

            // schedule sampler to play at hosttime
            scheduleSamplerTick(accented: isAccented, hostTime: nextTickHostTime)

            // update beat so ui can follow
            let uiBeat = beat
            DispatchQueue.main.async { [weak self] in
                self?.onBeatChange?(uiBeat)
            }

            beatIndex += 1
            let periodHost = secondsToHostTime(tickPeriodSeconds)
            nextTickHostTime &+= periodHost
        }
    }

    // schedules sampler tick to play at specific host time
    // transportRunID used to cancle pending ticks if metro gets paused
    private func scheduleSamplerTick(accented: Bool, hostTime: UInt64) {
        let runID = transportRunID
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }
            
            // check if transport still running, if runID is still current
            // check before and after delay
            guard self.isTransportRunning, self.transportRunID == runID else {return }
            self.waitUntilHostTime(hostTime, runID: runID)

            guard self.isTransportRunning, self.transportRunID == runID else { return }
            
            // if here, transport is running, so play notes
            if accented {
                self.hiSampler.play(noteNumber: 60, velocity: 127, channel: 0)
            } else {
                self.loSampler.play(noteNumber: 60, velocity: 127, channel: 0)
            }
        }
    }

    private func waitUntilHostTime(_ target: UInt64, runID: UUID) {
        // steadier solution for sequencing than appleSequencer
        // Busy-wait with short sleep for procise host times
        // trades a  bit of cpu  for more coonstant beat alignment

        while true {
            // check if cancelled
            if !isTransportRunning || transportRunID != runID { return }
            
            guard let now = currentHostTime() else { return }
            if now >= target { return }
            // sleep 0.2ms ish to avoid pegging CPU     
            usleep(200)
        }
    }
    
    func hostTimeForUnixTimestamp(_ timestamp: Double) -> UInt64? {
        guard let nowHost = currentHostTime() else { return nil }
        let nowUnix = Date().timeIntervalSince1970
        let delta = timestamp - nowUnix
        return nowHost &+ secondsToHostTime(delta)
    }

    func audioHostTime() -> UInt64? {
        engine.avEngine.outputNode.lastRenderTime?.hostTime
    }
    
    
    func setTempo(_ bpm: Double) {
        print("Setting tempo to \(bpm)")
        tempo = bpm
        updateTickPeriod()
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
        // add newest tap too array
        tapTimestamps.append(now)
        
        // calculate interval between now and last tap
        if tapTimestamps.count > 1 {
            let prevTap = tapTimestamps[tapTimestamps.count - 2]
            let recentInterval = now - prevTap

            // ensure all recent taps are within a fair amount of time
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
