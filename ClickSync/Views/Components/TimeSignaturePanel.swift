//
//  TimeSignaturePicker.swift
//  ClickSync
//
//  Created by George Casartelli on 18/12/2025.
//

import SwiftUI

struct TimeSignatureOptions: View {
    let options: [Int]
    let current: Int
    var onSelect: (Int) -> Void
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                ForEach (options, id: \.self) { value in
                    Button { onSelect(value) } label: {
                        Text("\(value)")
                            .secondaryStyle()
                            .foregroundStyle(value == current ? .orange : .white.opacity(0.6))
                    }
                    
                }
            }
        }
        .frame(height: 100)
    }
}

/// UI component for time sig selection with dropdown style components
///  UI needs to be made much simpler (remove geometryReader) but no time left
struct TimeSignaturePanel: View {
    @Binding var top: Double
    @Binding var bottom: Double
    
    @State private var editingTop = false
    @State private var editingBottom = false
    
    private let topValues = Array(1...12)
    private let bottomValues = [1,2,4,8]
    

    var body: some View {
        HStack{
            GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        if editingTop {
                            TimeSignatureOptions(options: topValues, current: Int(top), onSelect: { newValue in
                                    top = Double(newValue)
                                withAnimation(.easeIn(duration:0.2)) { editingTop = false }
                                
                            }
                        )
                            
                        }
                        else {
                            Button() {
                                withAnimation(.easeIn(duration:0.2)) { editingTop.toggle() }
                            } label: {
                                Text("\(Int(top))").mainStyle()
                            }
                        }
                    }.position(
                        x: geo.frame(in: .local).midX - 40,
                        y: geo.frame(in: .local).midY
                    )
                    
                Text(" / ").mainStyle().position(
                    x: geo.frame(in: .local).midX,
                    y: geo.frame(in: .local).midY
                )
                
                    
                    ZStack {
                        if editingBottom {
                            TimeSignatureOptions(
                                options: bottomValues,
                                current: Int(bottom),
                                onSelect: { newValue in
                                    bottom = Double(newValue)
                                    withAnimation(.easeIn(duration:0.2)) { editingBottom = false
                                    }
                                }
                            )
                        }
                        else {
                            Button() {
                                withAnimation(.easeIn(duration:0.2)) { editingBottom.toggle() }
                            } label: {
                                Text("\(Int(bottom))").mainStyle()
                            }
                            
                        }
                    }.position(
                        x: geo.frame(in: .local).midX + 40,
                        y: geo.frame(in: .local).midY
                    )
            }.frame(width: 200, height: (editingTop || editingBottom) ? 120 : 60)
            
        }.background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.teal.opacity(0.4))
        }
    }
}

