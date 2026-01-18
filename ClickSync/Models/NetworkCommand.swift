//
//  NetworkCommand.swift
//  ClickSync
//
//  Created by George Casartelli on 18/01/2026.
//

import Foundation

enum NetworkAction: String, Codable {
    case start
    case stop
    case setBPM
    case cueBPM
}

enum DeviceRole: String, Codable {
    case master
    case client
    case none
}

struct NetworkCommand: Codable {
    var action: NetworkAction
    var sender: DeviceRole
    var bpm: Double? = nil
    var startTime: TimeInterval? = nil
    
    init(
        action: NetworkAction,
        sender: DeviceRole,
        bpm: Double? = nil,
        startTime: TimeInterval? = nil
    ) {
        self.action = action
        self.sender = sender
        self.bpm = bpm
        self.startTime = startTime
    }
}
