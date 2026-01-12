//
//  BPMControl.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct BPMControl: View {
    
    @Binding var bpm: Double
    
    var bpmFieldFocused: FocusState<Bool>.Binding
    
    @State private var dragStartValue: Double = 0
    @State private var isDragging = false
    @State private var dragDir: DragDirection? = nil
    @State private var bpmText: String = ""
    
    enum DragDirection {
        case up
        case down
    }
    
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var lastHaptic: Int = 0
    
    let minBPM: Double = 40
    let maxBPM: Double = 300
    let dragSensitivity: Double = 0.2
    
    private var textColor: Color {
        guard isDragging else { return .orange}
        
        switch dragDir {
        case .up: return .green
        case .down: return .red
        case .none: return .orange
        }
    }
    
    
    var body: some View {
        ZStack{
            VStack{
                HStack {
                    TextField("", text: $bpmText)
                        .keyboardType(.numberPad)
                        .focused(bpmFieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.system(.title, design: .monospaced))
                        .foregroundStyle(textColor)
                        .scaleEffect(isDragging ? 1.08 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isDragging)
                        .fontWeight(.heavy)
                        .shadow(color: isDragging ? .orange.opacity(0.6) : .clear, radius: isDragging ? 8 : 0)
                        .frame(width: 90)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    commitTypedBPM()
                                }
                            }
                        }
                    
                    Text("BPM")
                        .mainStyle()
                    
                }
                .contentShape(Rectangle())

                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let deltaH = value.translation.width * dragSensitivity
                            let deltaV = -value.translation.height * dragSensitivity
                            var newBPM = dragStartValue + deltaH + deltaV
                            newBPM = min(max(newBPM, minBPM), maxBPM)
                            
                            if newBPM > dragStartValue {
                                dragDir = .up
                            } else {
                                dragDir = .down
                            }
                            bpm = round(newBPM)
                            print("\(bpm)")
                            if Int(bpm) % 10 == 0 {
                                if Int(bpm) != lastHaptic {
                                    hapticGenerator.impactOccurred()
                                    lastHaptic = Int(bpm)
                                }
                                
                            }
                            if abs(Int(bpm)-lastHaptic) > 1 {
                                lastHaptic = 0
                            }
                        }
                        .onEnded { _ in
                            dragStartValue = bpm
                            isDragging = false
                            dragDir = .none
                        }
                )
                .onAppear {
                    bpmText = "\(Int(bpm))"
                    dragStartValue = bpm
                }
                .onChange(of: bpm) { newValue in
                    bpmText = "\(Int(newValue))"
                }
                .onChange(of: bpmFieldFocused.wrappedValue) { focused in
                    if !focused {
                        commitTypedBPM()
                    }
                }
            }
            .frame(width: 200, height: 60)
        }
        
        
    }
    
    private func commitTypedBPM() {
        let cleaned = bpmText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let value = Double(cleaned) else {
            bpmText = "\(Int(bpm))"
            return
        }
        
        let clamped = min(max(value, minBPM), maxBPM)
        bpm = round(clamped)
        bpmText = "\(Int(bpm))"
        dragStartValue = bpm
    }
}

