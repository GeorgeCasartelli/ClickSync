//
//  AccentPickerView.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct AccentPickerView: View {
    
    
    @Environment(\.horizontalSizeClass) private var hSize
    private var isPhone:Bool {hSize == .compact}
    
    
    let beatCount: Int
    let accentedBeats: Set<Int>
    let currentBeat: Int
    let bpm: Double
    let onTapBeat: (Int) -> Void
    
    // calculation for beat display dividers
    var dividerInterval: Int? {
        if beatCount == 3 || beatCount == 4 || beatCount == 5 { return nil} // return nothing if 3 4 or 5
        if beatCount % 5 == 0 { return 5 }
        if beatCount % 4 == 0 { return 4 }
        if beatCount % 3 == 0 { return 3 }
        if beatCount == 11 { return 4 }
        return nil // nothing for 7, 11,
    }
    
    var body: some View {
        let circleSize: CGFloat = beatCount <= 8 ? (isPhone ? 18 : 24) : (beatCount <= 10 ? (isPhone ? 16 : 24) : (isPhone ? 14 : 24))
        let spacing: CGFloat = beatCount <= 4 ? 16 : (beatCount <= 8 ? 12 : 8)
        
    
        let row = HStack(spacing: spacing) {
            ForEach(0..<beatCount, id: \.self) { beat in
                BeatCircle(
                    isCurrent: beat == currentBeat,
                    isAccented: accentedBeats.contains(beat),
                    bpm: bpm,
                    size: circleSize,
                    onTap: { onTapBeat(beat) }
                )

                    .onTapGesture {
                        onTapBeat(beat)
                    }
                    .padding(.trailing, ((beat + 1) % 4 == 0 && beat != beatCount - 1) ? 4 : 4)
                if let interval = dividerInterval, (beat + 1) % interval == 0 && beat != beatCount - 1 {
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 2, height: 20)

                }
            }
            
        }
        .padding(.horizontal, 12)
        .frame(height:50)
        
        
        withAnimation(.easeInOut(duration: 0.5)) {
            Group {
                if isPhone && beatCount >= 13 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        row
                    }.background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.teal.opacity(0.2))
                    )
                } else {
                    row
                        .frame(maxWidth: .infinity)
                }
            }
        }
        
        

    }
}
