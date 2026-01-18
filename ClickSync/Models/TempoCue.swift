//
//  TempoCue.swift
//  ClickSync
//
//  Created by George Casartelli on 18/01/2026.
//

import Foundation

struct TempoCue: Identifiable, Equatable, Codable{
    let id: UUID
    var label: String
    var bpm: Double
    
    init(label: String, bpm: Double, id: UUID = UUID()) {
        self.id = id
        self.label = label
        self.bpm = bpm
    }
    
    func getID() -> UUID {
        return id
    }
}
