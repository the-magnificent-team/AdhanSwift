//
//  Prayer.swift
//  AdhanSwift
//
//  Created by ahmad alhayek on 2/2/25.
//

import Foundation

public struct Prayer: Equatable, Hashable, Codable, Sendable, Identifiable {
    public let prayerName: Name

    /// prayer time in GTC
    public let prayerTime: Date

    public var id: Name {
        prayerName
    }

    public enum Name: String, Codable, Hashable, Sendable, CaseIterable {
        case fajr
        case sunrise
        case dhuhr
        case asr
        case maghrib
        case isha
    }
}
