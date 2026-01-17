//
//  MetronomeView.swift
//  ClickSync
//
//  Created by George Casartelli on 05/01/2026.
//

import SwiftUI

struct MetronomeView: View {
    
    @Environment(\.horizontalSizeClass) private var hSize
    private var isPhone:Bool {hSize == .compact}
    
    @EnvironmentObject var metroVM: ViewModel
    @EnvironmentObject private var multipeerManager:  MultipeerManager

    @FocusState private var bpmFocused: Bool
    
    @State private var bpmDraft: Double = 120
    @State private var isEditingBpm = false
    
    @Binding var showCueButtons: Bool
    
    @State private var editingCue: TempoCue? = nil
    
    let bottomValues = [1.0, 2.0, 4.0, 8.0]
    
    
    var body: some View {
        
        ZStack {
//            Color(red: 0.06, green: 0.06, blue: 0.06)
//                .ignoresSafeArea()
            
            
            
            
            VStack(spacing: 20) {
                
                Spacer()
 
                BPMControl(
                    bpm: $bpmDraft,
                    disabled: multipeerManager.role == .client,
                    bpmFieldFocused: $bpmFocused,
                    onDragStart: {
                        isEditingBpm = true
                    },
                    onDragEnd: { finalBPM in
                        isEditingBpm = false
                        metroVM.requestTempoChange(finalBPM, mode: .immediate)
                        guard multipeerManager.role == .master else { return }
                        guard !multipeerManager.connectedPeers.isEmpty else { return }
                        multipeerManager.sendCommand([
                            "action":"setBPM",
                            "sender":"master",
                            "bpm":finalBPM
                            
                        ])
                    },
                    
                    onCommit: { committedBpm in
                        metroVM.requestTempoChange(committedBpm, mode: .immediate)
                        guard multipeerManager.role == .master else { return }
                        guard !multipeerManager.connectedPeers.isEmpty else { return }
                        multipeerManager.sendCommand([
                            "action": "setBPM",
                            "sender": "master",
                            "bpm": committedBpm
                        ])
                    }
                )
                .padding()
                .onTapGesture {
                    guard multipeerManager.role != .client else { return }
                    bpmFocused = true
                }
                
                if !isPhone { Spacer() }
                
                ZStack{
//                    Circle()
//                        .fill(Color.orange.opacity(0.3))
//                        .frame(width: metroVM.isPlaying ? 100 : 80,
//                               height: metroVM.isPlaying ? 100 : 80)
//                        .animation(.easeOut(duration: 0.6).repeatForever(autoreverses: true), value: metroVM.isPlaying)
                    Button {
                        metroVM.togglePlay(multipeer: multipeerManager)
                    } label: {
                        
                        Text(metroVM.playIcon)
                            .font(.system(size: isPhone ? 60 : 80, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: isPhone ? 90 : 130, height: isPhone ? 90 : 130)
                            .background(
                                Circle()
                                    .fill(metroVM.playButtonColor)
                                    .shadow(radius: 4)
                            )
                            .scaleEffect(metroVM.pulseSize)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: metroVM.isPlaying)
                    }
                }
                
                Spacer()
                
                //                    VStack(spacing: 6) {
                //                        if let queued = metroVM.pendingBpm {
                //                            Text("Queued -> \(Int(queued))")
                //                                .font(.caption)
                //                                .foregroundStyle(.orange.opacity(0.8))
                //                        }
                
                
                
                VStack(spacing: 12) {
                    TimeSignaturePanel(top: $metroVM.timeSigTop, bottom: $metroVM.timeSigBtm)
                        .onChange(of: metroVM.timeSigTop) { _ in
                            metroVM.updateTimeSignature(top: metroVM.timeSigTop, bottom: metroVM.timeSigBtm)}
                }
                
                AccentPickerView(
                    beatCount: Int(metroVM.timeSigTop),
                    accentedBeats: metroVM.accentedBeats,
                    currentBeat: metroVM.currentBeat,
                    bpm: metroVM.bpm,
                    onTapBeat: { beat in
                        metroVM.toggleAccent(beat: beat)
                    }
                )
                
                
                if !isPhone {
                    Button(action: metroVM.tapTempo) {
                        Text("TAP")
                            .generalTextStyle()
                            .padding()
                            .foregroundColor(.white)
                            .background(.orange)
                            .cornerRadius(10)
                    }
                }
                          
                
                if showCueButtons {

                    let queuedID = metroVM.queuedCueID
                    let currentBpmInt = Int(metroVM.bpm)

                    // build the row once
                    let cueRow =
                        HStack(spacing: 10) {
                            ForEach(metroVM.tempoCues) { cue in
                                let isQueued = (queuedID == cue.id)
                                let isCurrent = (currentBpmInt == Int(cue.bpm))

                                VStack(spacing: 4) {
                                    Text("\(Int(cue.bpm))").secondaryStyle()
                                    Text(cue.label).font(.caption).opacity(0.8).lineLimit(1)
                                }
                                .frame(maxWidth: 200, minHeight: 48)
                                .padding()
                                .foregroundColor(.white)
                                .background(isQueued ? .green : (isCurrent ? .orange : .gray.opacity(0.4)))
                                .cornerRadius(10)
                                .frame(width: 100)
                                .contentShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    metroVM.triggerTempoCue(cue, multipeer: multipeerManager)
                                }
                                .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 30) {
                                    print("LONG PRESS \(cue.label)")
                                    withAnimation(.easeInOut(duration: 0.18)) { editingCue = cue }
                                }

                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    VStack {
                        Text("Cue bpm change...").generalTextStyle()

                        Group {
                            if isPhone {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    cueRow
                                }
                            } else {
                                cueRow
                                    .frame(maxWidth: .infinity) // iPad: show all, no scroll
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.teal.opacity(isPhone ? 0.3 : 0.0))
                        )
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    if isPhone {
                        Button(action: metroVM.tapTempo) {
                            Text("TAP")
                                .generalTextStyle()
                                .padding()
                                .foregroundColor(.white)
                                .background(.orange)
                                .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
            }
            //                    }
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .overlay {
                if bpmFocused {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            bpmFocused = false
                        }
                }
            }
            
            
            
            if editingCue != nil  {
                TempoCueEditor(editingCue: $editingCue) { updated in
                    metroVM.updateCue(updated)
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
            
            
        }
        
        .padding()
        .animation(.easeInOut(duration: 0.18), value: editingCue != nil)
        .ignoresSafeArea(.keyboard, edges: .bottom)
     
        .onAppear {
            bpmDraft = metroVM.bpm
        }
        
            .onChange(of: metroVM.bpm) { newRealBPM in
                guard !isEditingBpm else { return }
                bpmDraft = newRealBPM
            }
        
            .onReceive(multipeerManager.$lastCommand) { cmd in
                guard multipeerManager.role == .client else { return }
                guard let cmd else { return }
                guard let action = cmd["action"] as? String, action == "setBPM" else { return }
                
                let bpmValue: Double?
                if let bpm = cmd["bpm"] as? Double { bpmValue = bpm }
                else if let n = cmd["bpm"] as? NSNumber { bpmValue = n.doubleValue}
                else { bpmValue = nil }
                
                guard let receivedBpm = bpmValue else { return }
                
                metroVM.requestTempoChange(receivedBpm)
            }
    }
}
