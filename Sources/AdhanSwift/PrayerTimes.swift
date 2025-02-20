//
//  PrayerTimes.swift
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

import CoreLocation
import Foundation
import SwiftUICore

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
                                                calculationParameters: calculationParameters)
            {
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


// MARK: extension

public extension PrayerTimes {
    init?(coordinates: Coordinates, date: DateComponents, method: CalculationMethodInput) {
        self.init(coordinates: coordinates, date: date, calculationParameters: method.calculationMethod.params)
    }

    init?(coordinates: Coordinates, date: DateComponents, calculationParameters: CalculationParameters) {
        var tempFajr: Date?
        var tempSunrise: Date?
        var tempDhuhr: Date?
        var tempAsr: Date?
        var tempMaghrib: Date?
        var tempIsha: Date?
        let cal = Calendar.gregorianUTC

        guard let prayerDate = cal.date(from: date),
              let tomorrowDate = cal.date(byAdding: .day, value: 1, to: prayerDate),
              let year = date.year,
              let dayOfYear = cal.ordinality(of: .day, in: .year, for: prayerDate)
        else {
            return nil
        }

        let tomorrow = cal.dateComponents([.year, .month, .day], from: tomorrowDate)

        guard let solarTime = SolarTime(date: date, coordinates: coordinates),
              let tomorrowSolarTime = SolarTime(date: tomorrow, coordinates: coordinates),
              let sunriseDate = cal.date(from: solarTime.sunrise),
              let sunsetDate = cal.date(from: solarTime.sunset),
              let tomorrowSunrise = cal.date(from: tomorrowSolarTime.sunrise)
        else {
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
                guard !calculationParameters.isMoonSightingCommittee else {
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
           sunsetDate < maghribDate, tempIsha?.compare(maghribDate) == .orderedDescending || tempIsha == nil
        {
            tempMaghrib = maghribDate
        }

        // if we don't have all prayer times then initialization failed
        guard let fajr = tempFajr,
              let sunrise = tempSunrise,
              let dhuhr = tempDhuhr,
              let asr = tempAsr,
              let maghrib = tempMaghrib,
              let isha = tempIsha
        else {
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
            .init(prayerName: .isha, prayerTime: _isha),
        ]
        self.coordinates = coordinates
        self.calculationParameters = calculationParameters
        dateComponent = date
    }
}
