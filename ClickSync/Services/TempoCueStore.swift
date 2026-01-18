//
//  TempoCueStore.swift
//  ClickSync
//
//  Created by George Casartelli on 18/01/2026.
//

import Foundation

class TempoCueStore {
    private let key = "tempoCues.v1"
    
    func load() -> [TempoCue]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode([TempoCue].self, from: data)
        } catch {
            print("TempoCueStore load decode error: \(error)")
            return nil
        }
    }
    
    func save(_ cues: [TempoCue]) {
        do {
            let data = try JSONEncoder().encode(cues)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("TempoCueStore save encode error: \(error)")
        }
    }
}
