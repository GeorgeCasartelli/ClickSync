//
//  BeatCircle.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

/// Visual beat indicator used in the accent picker. Pulses purple when beat is current
import SwiftUI

struct BeatCircle: View {
    let isCurrent: Bool
    let isAccented: Bool
    let bpm: Double
    let size: CGFloat
    let onTap: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    
    var body: some View {
        let beatDuration = 60.0 / bpm
        
        let fadeDuration = max(beatDuration * 1.0, 0.5)
        let settleDuration = max(beatDuration * 1.0, 0.5)
        Circle()
        
            .fill(
                isAccented ? Color.orange : // accented ones
                Color.gray.opacity(0.3) // default
            )
            .overlay(
                Circle().stroke(.white.opacity(isAccented ? 0.0 : 0.3), style: StrokeStyle(lineWidth: 1, dash:[3,3]))
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(Color.purple)
                    .opacity(pulseOpacity) // fade
            )
            .scaleEffect(pulseScale)
            .shadow(color:
                        isAccented ? .orange :
                        .clear,
                        radius: isAccented ? 6 : 0)
        
            .onChange(of: isCurrent) { newValue in
                if newValue {
                    
                    // snap in
                    pulseScale = 1.35
                    pulseOpacity = 1.0
                    
                    // fast enlarge
                    withAnimation(.easeOut(duration: 0.08)) {
                        pulseScale = 1.4
                    }
                    
                    // fade out
                    withAnimation(.easeOut(duration: fadeDuration)) {
                        pulseOpacity = 0.0
                    }
                    
                    withAnimation(.easeOut(duration: settleDuration)) {
                        pulseScale = 1.0
                    }
                } else {
                    withAnimation(.linear(duration: 0.05)) {
                        pulseOpacity = 0.0
                    }
                }
            }
            .onTapGesture(perform: onTap)
    }
}
