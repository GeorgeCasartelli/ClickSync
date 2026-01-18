//
//  VolumeBar.swift
//  ClickSync
//
//  Created by George Casartelli on 07/01/2026.
//

import SwiftUI


/// Simple custom vertical drag control for volume. UI-only, value is bound to viewmodel state
struct VolumeBar: View {
    let label: String
    @Binding var value: Float
    let color: Color
    
    let minVol: Float = 0
    let maxVol: Float = 8.0 // scaling
    let barHeight: CGFloat = 120
    
    @State private var dragStartVolume: Float = 0
  
    var body: some View {
        VStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))

            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(height: CGFloat(value / maxVol) * 120),
                    alignment: .bottom
                )
                .frame(width: 36, height: 120)
                .gesture(
                    DragGesture()
                        .onChanged { drag in
                            
                            // map drag (pixels) into volume delta
                           let delta = Float(-drag.translation.height) / Float(barHeight) * maxVol
                           let newValue = dragStartVolume + delta
                           value = min(max(newValue, minVol), maxVol)

                        }
                        .onEnded { _ in
                            // nothing to persist; next drag will capture new start
                            dragStartVolume = value

                            
                        }

                                    
                )
                .onAppear {
                    dragStartVolume = value
                }
        }
        
    }
}

