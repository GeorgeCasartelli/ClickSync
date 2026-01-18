import SwiftUI


/// Editor for a tempo cue. UI-only, edits local draft state then returns updates state through"Save"
struct TempoCueEditor: View {

    @Binding var editingCue: TempoCue?
    var onSave: (TempoCue) -> Void

    @State private var labelText = ""
    @State private var bpmText = ""
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case label, bpm
    }

    var body: some View {
        if let cue = editingCue {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if focusedField != nil {
                            focusedField = nil
                        } else {
                            dismiss()
                        }
                    }
                
                
                VStack(spacing: 16) {

                    Text("Edit Tempo Cue")
                        .mainStyle()

                    VStack(spacing: 12) {
                        TextField("Label", text: $labelText)
                            .textInputAutocapitalization(.characters)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .focused($focusedField, equals: .label)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = .bpm
                            }

                        TextField("BPM", text: $bpmText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .focused($focusedField, equals: .bpm)
                        
                    }

                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .generalTextStyle()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.35))
                                .cornerRadius(10)
                        }
                        
                        Button {
                            focusedField = nil
                            save(from: cue)
                        } label: {
                            Text("Save")
                            .generalTextStyle()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                        }
                        
                    }
                }
                .padding()
                .frame(width: 280)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .fill(.black)
                            .opacity(0.7) )
                        
                        .shadow(radius:10)
                )
                .cornerRadius(20)
                .shadow(radius: 10)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focusedField = nil   // dismiss keyboard
                        }
                    }
                }
                .onAppear {
                    labelText = cue.label
                    bpmText = "\(Int(cue.bpm))"
                }
            }
        }
    }

    private func dismiss() {
        withAnimation { editingCue = nil }
    }

    private func save(from cue: TempoCue) {
        guard let bpm = Double(bpmText) else { return }
        var updated = cue
        updated.label = labelText.isEmpty ? cue.label : labelText
        updated.bpm = min(max(round(bpm), 40), 300)
        onSave(updated)
        dismiss()
    }
}
