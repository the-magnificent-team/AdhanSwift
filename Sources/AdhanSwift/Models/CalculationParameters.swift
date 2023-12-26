//
//  CalculationParameters.swift
//  Adhan
//
//  Copyright © 2018 Batoul Apps. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/**
  Customizable parameters for calculating prayer times
 */

public enum IshaPrayerAdjustments: Equatable, Codable, Sendable {
    case angle(Double)
    case time(Minute)
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .angle(let a0):
            try container.encode(a0, forKey: .ishaAngle)
          
        case .time(let a0):
            try container.encode(a0, forKey: .ishaInterval)
        }
    }
    
    enum CodingKeys: CodingKey, CaseIterable {
        case ishaAngle
        case ishaInterval
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let angle = try container.decodeIfPresent(Double.self, forKey: .ishaAngle)
        let min = try container.decodeIfPresent(Minute.self, forKey: .ishaInterval)
        
        if let angle {
            self = .angle(angle)
        } else if let min {
            self = .time(min)
        } else {
            throw DecodingError.valueNotFound(IshaPrayerAdjustments.self,
                                              .init(codingPath: CodingKeys.allCases, debugDescription: "CodingKeys not found ~ at least one of the values need to be present. "))
        }
    }
}

public struct CalculationParameters: Codable, Equatable, Sendable {
    public let fajrAngle: Double

    public let maghribAngle: Double?
    
    public let ishaPrayerAdjustments: IshaPrayerAdjustments
    
    public var madhab: Madhab
    
    public var highLatitudeRule: HighLatitudeRule?
    
    public var adjustments: PrayerAdjustments
    
    public let rounding: Rounding
    
    public var shafaq: Shafaq
    
    public let methodAdjustments: PrayerAdjustments
    
    public let isMoonSightingCommittee: Bool
    
    public init(fajrAngle: Double,
                maghribAngle: Double? = nil,
                ishaPrayerAdjustments: IshaPrayerAdjustments ,
                madhab: Madhab = .shafi,
                highLatitudeRule: HighLatitudeRule? = nil,
                adjustments: PrayerAdjustments = .init(),
                rounding: Rounding = .nearest,
                shafaq: Shafaq = .general,
                methodAdjustments: PrayerAdjustments = .init(),
                isMoonSightingCommittee: Bool = false) {
        self.fajrAngle = fajrAngle
        self.maghribAngle = maghribAngle
        self.ishaPrayerAdjustments = ishaPrayerAdjustments
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.adjustments = adjustments
        self.rounding = rounding
        self.shafaq = shafaq
        self.methodAdjustments = methodAdjustments
        self.isMoonSightingCommittee = isMoonSightingCommittee
    }


    func nightPortions(using coordinates: Coordinates) -> (fajr: Double, isha: Double) {
        let currentHighLatitudeRule = highLatitudeRule ?? .recommended(for: coordinates)

        switch currentHighLatitudeRule {
        case .middleOfTheNight:
            return (1/2, 1/2)
        case .seventhOfTheNight:
            return (1/7, 1/7)
        case .twilightAngle:
            return (self.fajrAngle / 60, self.ishaAngle / 60)
        }
    }
}


extension CalculationParameters {
    
    public var ishaAngle: Double {
        get {
            switch ishaPrayerAdjustments {
            case let .angle(double):
                return double
            case .time:
                return 0
            }
        }
    
    }
    
    public var ishaInterval: Minute? {
        get {
            switch ishaPrayerAdjustments {
            case .angle:
                return 0
            case let .time(min):
                return min
            }
        }
    }
}
