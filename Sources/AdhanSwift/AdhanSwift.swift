//
//  Qibla.swift
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
import SwiftUI
import CoreLocation

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

public struct PrayerTimes: Sendable {
    public let prayers: [Prayer]
    
    public let coordinates: Coordinates
    
    public let calculationParameters: CalculationParameters
    
    public let dateComponent: DateComponents
    
    
    public func currentPrayer(at time: Date = Date()) -> Prayer? {
        
        prayers.last {
            $0.prayerTime.timeIntervalSince(time) <= 0
        }
       
    }
    
    subscript(_ name: Prayer.Name) -> Prayer {
        prayers.first {
            $0.prayerName == name
        }!
    }
    
    

    public func nextPrayer(at time: Date = Date()) -> Prayer? {
        guard let prayer = prayers.last(where: {
            $0.prayerTime.timeIntervalSince(time) <= 0
        }), prayer != prayers.last else {
            let cal = Calendar.gregorianUTC
            if let date = cal.date(from: dateComponent),
               let nextDay = cal.date(byAdding: .day, value: 1, to: date),
               let nextDayPrayers = PrayerTimes(coordinates: coordinates,
                                                date: cal.dateComponents([.year, .month, .day], from: nextDay),
                                                calculationParameters: calculationParameters) {
                return nextDayPrayers[.fajr]
            }
            return nil
        }
       

        guard let index = prayers.lastIndex(of: prayer) else { return nil }

        return prayers[index + 1]
    }

    public func time(for prayer: Prayer.Name) -> Date {
        prayers.first {
            prayer == $0.prayerName
        }!.prayerTime
    }
}

/* Sunnah times for a location and date using the given prayer times.
 All prayer times are in UTC and should be displayed using a DateFormatter that
 has the correct timezone set. */
public struct SunnahTimes {

    /* The midpoint between Maghrib and Fajr */
    public let middleOfTheNight: Date

    /* The beginning of the last third of the period between Maghrib and Fajr,
     a recommended time to perform Qiyam */
    public let lastThirdOfTheNight: Date
}

extension SunnahTimes {
    public init?(from prayerTimes: PrayerTimes) {
        
        guard let date = Calendar.gregorianUTC.date(from: prayerTimes.dateComponent),
            let nextDay = Calendar.gregorianUTC.date(byAdding: .day, value: 1, to: date),
            let nextDayPrayerTimes = PrayerTimes(
                coordinates: prayerTimes.coordinates,
                date: Calendar.gregorianUTC.dateComponents([.year, .month, .day], from: nextDay),
                calculationParameters: prayerTimes.calculationParameters)
            else {
                // unable to determine tomorrow prayer times
                return nil
        }
        let maghribTime = prayerTimes[.maghrib].prayerTime

        let nightDuration = nextDayPrayerTimes[.fajr].prayerTime.timeIntervalSince(maghribTime)
        self.middleOfTheNight = maghribTime.addingTimeInterval(nightDuration / 2).roundedMinute()
        self.lastThirdOfTheNight = maghribTime.addingTimeInterval(nightDuration * (2 / 3)).roundedMinute()
    }
}


// MARK: Qibla
public struct Qibla {
    /* The heading to the Qibla from True North */
    public let direction: Double

    public init(coordinates: Coordinates) {
        let makkah = Coordinates(latitude: 21.4225241, longitude: 39.8261818)

        /* Equation from "Spherical Trigonometry For the use of colleges and schools" page 50 */
        let term1 = sin(makkah.longitudeAngle.radians - coordinates.longitudeAngle.radians)
        let term2 = cos(coordinates.latitudeAngle.radians) * tan(makkah.latitudeAngle.radians)
        let term3 = sin(coordinates.latitudeAngle.radians) * cos(makkah.longitudeAngle.radians - coordinates.longitudeAngle.radians)

        direction = Angle(radians: atan2(term1, term2 - term3)).unwound().degrees
    }
}


// MARK: extension
public extension PrayerTimes {
    
    init?(coordinates: Coordinates, date: DateComponents, method: CalculationMethodInput) {
        self.init(coordinates: coordinates, date: date, calculationParameters: method.calculationMethod.params)
    }
    
    
    init?(coordinates: Coordinates, date: DateComponents, calculationParameters: CalculationParameters) {
        
        var tempFajr: Date? = nil
        var tempSunrise: Date? = nil
        var tempDhuhr: Date? = nil
        var tempAsr: Date? = nil
        var tempMaghrib: Date? = nil
        var tempIsha: Date? = nil
        let cal = Calendar.gregorianUTC
        
        guard let prayerDate = cal.date(from: date),
              let tomorrowDate = cal.date(byAdding: .day, value: 1, to: prayerDate),
              let year = date.year,
              let dayOfYear = cal.ordinality(of: .day, in: .year, for: prayerDate) else {
              return nil
          }
        
        let tomorrow = cal.dateComponents([.year, .month, .day], from: tomorrowDate)
        
        guard let solarTime = SolarTime(date: date, coordinates: coordinates),
            let tomorrowSolarTime = SolarTime(date: tomorrow, coordinates: coordinates),
            let sunriseDate = cal.date(from: solarTime.sunrise),
            let sunsetDate = cal.date(from: solarTime.sunset),
            let tomorrowSunrise = cal.date(from: tomorrowSolarTime.sunrise) else {
                // unable to determine transit, sunrise or sunset aborting calculations
                return nil
        }
        
        tempSunrise = cal.date(from: solarTime.sunrise)
        tempMaghrib = cal.date(from: solarTime.sunset)
        tempDhuhr = cal.date(from: solarTime.transit)
        
        if let asrComponents = solarTime.afternoon(shadowLength: calculationParameters.madhab.shadowLength) {
            tempAsr = cal.date(from: asrComponents)
        }

        // get night length
        let night = tomorrowSunrise.timeIntervalSince(sunsetDate)

        if let fajrComponents = solarTime.timeForSolarAngle(Angle(-calculationParameters.fajrAngle), afterTransit: false) {
            tempFajr = cal.date(from: fajrComponents)
        }

        // special case for moonsighting committee above latitude 55
        if calculationParameters.isMoonSightingCommittee && coordinates.latitude >= 55 {
            let nightFraction = night / 7
            tempFajr = sunriseDate.addingTimeInterval(-nightFraction)
        }
        
        let safeFajr: Date = {
            guard !calculationParameters.isMoonSightingCommittee else {
                return Astronomical.seasonAdjustedMorningTwilight(latitude: coordinates.latitude, day: dayOfYear, year: year, sunrise: sunriseDate)
            }

            let portion = calculationParameters.nightPortions(using: coordinates).fajr
            let nightFraction = portion * night

            return sunriseDate.addingTimeInterval(-nightFraction)
        }()

        if tempFajr == nil || tempFajr?.compare(safeFajr) == .orderedAscending {
            tempFajr = safeFajr
        }

        // Isha calculation with check against safe value
        
        switch calculationParameters.ishaPrayerAdjustments {
            
        case .angle:
            if let ishaComponents = solarTime.timeForSolarAngle(Angle(-calculationParameters.ishaAngle), afterTransit: true) {
                tempIsha = cal.date(from: ishaComponents)
            }

            // special case for moonsighting committee above latitude 55
            if calculationParameters.isMoonSightingCommittee && coordinates.latitude >= 55 {
                let nightFraction = night / 7
                tempIsha = sunsetDate.addingTimeInterval(nightFraction)
            }

            let safeIsha: Date = {
                guard !calculationParameters.isMoonSightingCommittee  else {
                    return Astronomical.seasonAdjustedEveningTwilight(latitude: coordinates.latitude, day: dayOfYear, year: year, sunset: sunsetDate, shafaq: calculationParameters.shafaq)
                }

                let portion = calculationParameters.nightPortions(using: coordinates).isha
                let nightFraction = portion * night

                return sunsetDate.addingTimeInterval(nightFraction)
            }()

            if tempIsha == nil || tempIsha?.compare(safeIsha) == .orderedDescending {
                tempIsha = safeIsha
            }
        case let .time(min):
            tempIsha = tempMaghrib?.addingTimeInterval(min.timeInterval)
        }
    
        
        // Maghrib calculation with check against safe value
        if let maghribAngle = calculationParameters.maghribAngle,
            let maghribComponents = solarTime.timeForSolarAngle(Angle(-maghribAngle), afterTransit: true),
            let maghribDate = cal.date(from: maghribComponents),
            // maghrib is considered safe if it falls between sunset and isha
            sunsetDate < maghribDate, (tempIsha?.compare(maghribDate) == .orderedDescending || tempIsha == nil) {
                tempMaghrib = maghribDate
        }
        
        // if we don't have all prayer times then initialization failed
        guard let fajr = tempFajr,
            let sunrise = tempSunrise,
            let dhuhr = tempDhuhr,
            let asr = tempAsr,
            let maghrib = tempMaghrib,
            let isha = tempIsha else {
                return nil
        }
        
        // Assign final times to public struct members with all offsets
        let _fajr = fajr.addingTimeInterval(calculationParameters.adjustments.fajr.timeInterval)
            .addingTimeInterval(calculationParameters.methodAdjustments.fajr.timeInterval)
            .roundedMinute(rounding: calculationParameters.rounding)

        let _sunrise = sunrise.addingTimeInterval(calculationParameters.adjustments.sunrise.timeInterval)
            .addingTimeInterval(calculationParameters.methodAdjustments.sunrise.timeInterval)
            .roundedMinute(rounding: calculationParameters.rounding)

        let _dhuhr = dhuhr.addingTimeInterval(calculationParameters.adjustments.dhuhr.timeInterval)
            .addingTimeInterval(calculationParameters.methodAdjustments.dhuhr.timeInterval)
            .roundedMinute(rounding: calculationParameters.rounding)

        let _asr = asr.addingTimeInterval(calculationParameters.adjustments.asr.timeInterval)
            .addingTimeInterval(calculationParameters.methodAdjustments.asr.timeInterval)
            .roundedMinute(rounding: calculationParameters.rounding)

        let _maghrib = maghrib.addingTimeInterval(calculationParameters.adjustments.maghrib.timeInterval)
            .addingTimeInterval(calculationParameters.methodAdjustments.maghrib.timeInterval)
            .roundedMinute(rounding: calculationParameters.rounding)

        let _isha = isha.addingTimeInterval(calculationParameters.adjustments.isha.timeInterval)
            .addingTimeInterval(calculationParameters.methodAdjustments.isha.timeInterval)
            .roundedMinute(rounding: calculationParameters.rounding)
        
        
        prayers = [
            .init(prayerName: .fajr, prayerTime: _fajr),
            .init(prayerName: .sunrise, prayerTime: _sunrise),
            .init(prayerName: .dhuhr, prayerTime: _dhuhr),
            .init(prayerName: .asr, prayerTime: _asr),
            .init(prayerName: .maghrib, prayerTime: _maghrib),
            .init(prayerName: .isha, prayerTime: _isha)
            
        ]
        self.coordinates = coordinates
        self.calculationParameters = calculationParameters
        self.dateComponent = date
    }
}
