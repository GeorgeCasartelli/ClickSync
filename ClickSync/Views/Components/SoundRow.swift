//
//  SoundRow.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct SoundRow: View {
    let name: String
    let isSelected: Bool
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(name)
                .generalTextStyle()
                .foregroundStyle(isSelected ? .orange : .gray)
                .shadow(color: .white.opacity(isSelected ? 0.4 : 0), radius: 4)

            Spacer()

            // LED “indicator light”
            Circle()
                .fill(isSelected ? Color.orange : Color.gray.opacity(0.3))
                .frame(width: 14, height: 14)
                .shadow(color: isSelected ? .orange : .clear, radius: isSelected ? 6 : 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.red.opacity(0.1) : Color.black.opacity(isSelected ? 0.45 : 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.orange.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 1)
                        .shadow(color: isSelected ? .yellow.opacity(0.7) : .clear, radius: 8)
                )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
    }
}

