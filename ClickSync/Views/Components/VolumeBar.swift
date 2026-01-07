//
//  VolumeBar.swift
//  ClickSync
//
//  Created by George Casartelli on 07/01/2026.
//

import SwiftUI


struct VolumeBar: View {
    let label: String
    @Binding var value: Float
    let color: Color
    
    let minVol: Float = 0
    let maxVol: Float = 8.0
    let barHeight: Float = 120
    
    @State private var dragStartValue: Float = 1.0
  
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
                            
                            let dragAmount = -Float(drag.translation.height) + Float(dragStartValue)
                             
                            let clamped = min(max(dragAmount, 0.0), barHeight)
                            let mapped = clamped / barHeight * maxVol
                            value = Float(mapped)

                        }
                        .onEnded { _ in
                            // nothing to persist; next drag will capture new start
                            dragStartValue = value / maxVol * barHeight

                            
                        }

                                    
                )
        }
        
    }
}

