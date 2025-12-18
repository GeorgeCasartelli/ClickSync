//
//  BPMControl.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct BPMControl: View {
    
    @Binding var bpm: Double
    
    @State private var isEditing = false
    @State private var dragStartValue: Double = 0
    
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var lastHaptic: Int = 0
    
    let minBPM: Double = 40
    let maxBPM: Double = 300
    let dragSensitivity: Double = 0.2
    
    var body: some View {
        ZStack{

            VStack{
                Text("\(Int(bpm)) BPM").mainStyle()
                
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let deltaH = value.translation.width * dragSensitivity
                                let deltaV = -value.translation.height * dragSensitivity
                                var newBPM = dragStartValue + deltaH + deltaV
                                newBPM = min(max(newBPM, minBPM), maxBPM)
                                
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
                            }
                    )
                    .onAppear { dragStartValue = bpm }
            }
        }
        .frame(width: isEditing ? 330 : 200, height: isEditing ? 80 :  60)
    }
}
