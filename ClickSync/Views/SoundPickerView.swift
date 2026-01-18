//
//  SoundPickerView.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//
import SwiftUI

// ALL SOUNDS IN THIS SOUND PICKER VIEW GAINED FROM https://www.reddit.com/r/audioengineering/comments/kg8gth/free_click_track_sound_archive/

struct SoundPickerView: View {
    let availableSounds: [String]
    let selectedSound: String
    let onSelectSound: (String) -> Void

    var body: some View {
        
        ZStack {
            Color(.black).opacity(0.4)

            VStack(spacing: 20) {
                Text("Sound Selector")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.5), radius: 8)

                // card container
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(availableSounds, id: \.self) { sound in
                            let displayName = sound.replacingOccurrences(of: "_", with: " ")
                            let isSelected = selectedSound == sound

                            SoundRow(
                                name: displayName,
                                isSelected: isSelected
                            ) {
                                onSelectSound(sound)
                            }
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .blur(radius: 80)
                            .ignoresSafeArea()
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
