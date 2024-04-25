//
//  File.swift
//  
//
//  Created by Ahmad Alhayek on 3/24/24.
//

import Foundation
import Time
import SwiftUI

enum PrayerTimesError: Error {
    case astronomicalTimeMustBeNormal
}

public struct ClockPrayer: Sendable {
    public let name: Prayer.Name
    
    /// prayer time in GTC
    public let time: Fixed<Second>
    
    /// Prayer time in current calendar
    public var currentTime: Fixed<Second> {
        get throws {
            try time.converted(to: Region.current, behavior: .preservingRange)
        }
    }
}

public struct PrayerClockTimes: Sendable {
    public let prayers: [ClockPrayer]
}

// MARK: Time
public extension PrayerClockTimes {
    init(coordinates: Coordinates,
         day: Fixed<Day>,
         method: CalculationMethodInput) throws {
        
        let day = try Fixed<Day>.init(region: .posix, year: day.year, month: day.month, day: day.day)
        
        let nextDay = day.nextDay
        
        let solarTime = try SolarClockTime(day: day, coordinates: coordinates)
        
        
        let sunrise = solarTime.sunriseTime
        let sunset = solarTime.sunsetTime
        let duhur = solarTime.transitTime
    
        let calculationParameters = method.calculationMethod.params
        
        let asr = try solarTime.afternoon(shadowLength: calculationParameters.madhab.shadowLength)
        
        let fajrPrayer = try Self.fajrPrayer(forDay: day, coordinates: coordinates, with: calculationParameters)
        
        let sunrisePrayer = ClockPrayer(name: .sunrise,
                                        time: sunrise.adjust(to: calculationParameters, prayer: .sunrise))
        
        let duhurPrayer = ClockPrayer(name: .dhuhr,
                                      time: duhur.adjust(to: calculationParameters, prayer: .dhuhr))
        
        let asrPrayer = ClockPrayer(name: .asr, time: asr.adjust(to: calculationParameters, prayer: .asr))
        
        let ishaPrayer = try Self.ishaPrayer(forDay: day, coordinates: coordinates, with: calculationParameters)
        
        let maghrib: Fixed<Second> = {
            if let maghribAngle = calculationParameters.maghribAngle,
               let maghribTime = try? solarTime.timeForSolarAngle(Angle(-maghribAngle), afterTransit: true),
               sunset < maghribTime,
               ishaPrayer.time > maghribTime {
                return maghribTime
            }
            
            return sunset
        }()
        
        let maghribPrayer = ClockPrayer(name: .maghrib,
                                        time: maghrib)
        
        prayers = [fajrPrayer, sunrisePrayer, duhurPrayer, asrPrayer, maghribPrayer, ishaPrayer]
    }

    /// Get fajr time for a prayer
    /// - Parameters:
    /// - day The day which the fajr time need to be calculated
    /// - coordinates: The location
    /// - calculationParameters: Calculation method
    static func fajrPrayer(forDay day: Fixed<Day>,
                           coordinates: Coordinates,
                           with calculationParameters: CalculationParameters) throws -> ClockPrayer {
        let solarTime = try SolarClockTime(day: day, coordinates: coordinates)
        let tomorrowSolarTime = try SolarClockTime(day: day.nextDay, coordinates: coordinates)
        let tomorrowSunrise = tomorrowSolarTime.sunriseTime
        let sunrise = solarTime.sunriseTime
        let sunset = solarTime.sunsetTime
        
        let night = tomorrowSunrise.firstInstant.date.timeIntervalSince(sunset.firstInstant.date)
        
        var fajr = try solarTime.timeForSolarAngle(Angle(-calculationParameters.fajrAngle), afterTransit: false)
        if calculationParameters.isMoonSightingCommittee && coordinates.latitude >= 55 {
            let nightFraction = night / 7
            fajr = fajr.subtracting(seconds: Int(nightFraction))
        }
        
        let safeFajr: Fixed<Second> = {
            guard !calculationParameters.isMoonSightingCommittee else {
                return Astronomical.seasonAdjustedMorningTwilight(latitude: coordinates.latitude,
                                                                  day: day.dayOfYear, year: day.year, sunrise: sunrise)
            }
            let portion = calculationParameters.nightPortions(using: coordinates).fajr
            let nightFraction = portion * night
            let date = sunrise.subtracting(seconds: Int(nightFraction))

            return date
        }()
        
        if fajr < safeFajr {
            fajr = safeFajr
        }
        fajr = fajr.adjust(to: calculationParameters, prayer: .fajr)
        
        
        return .init(name: .fajr,
                     time: fajr)
    }
    
    static func ishaPrayer(forDay day: Fixed<Day>,
                           coordinates: Coordinates,
                           with calculationParameters: CalculationParameters) throws -> ClockPrayer {
        let solarTime = try SolarClockTime(day: day, coordinates: coordinates)
        let tomorrowSolarTime = try SolarClockTime(day: day.nextDay, coordinates: coordinates)
        let tomorrowSunrise = tomorrowSolarTime.sunriseTime
        let sunrise = solarTime.sunriseTime
        let sunset = solarTime.sunsetTime
        
        let night = tomorrowSunrise.firstInstant.date.timeIntervalSince(sunset.firstInstant.date)
        
        var isha: Fixed<Second>
        switch calculationParameters.ishaPrayerAdjustments {
            
        case .angle:
            isha = try solarTime.timeForSolarAngle(Angle(-calculationParameters.ishaAngle), afterTransit: true)

            // special case for moonsighting committee above latitude 55
            if calculationParameters.isMoonSightingCommittee && coordinates.latitude >= 55 {
                let nightFraction = night / 7
                isha = sunrise.adding(seconds: Int(nightFraction))
            }

            let safeIsha: Fixed<Second> = {
                guard !calculationParameters.isMoonSightingCommittee  else {
                    return Astronomical.seasonAdjustedEveningTwilight(latitude: coordinates.latitude, day: day.dayOfYear,
                                                                      year: day.year, sunset: sunset, shafaq: calculationParameters.shafaq)
                }

                let portion = calculationParameters.nightPortions(using: coordinates).isha
                let nightFraction = portion * night
                
                return sunset.adding(seconds: Int(nightFraction))
            }()

            if isha > safeIsha {
                isha = safeIsha
            }
        case let .time(min):
            isha = sunset.adding(seconds: Int(min.timeInterval))
        }
        
        isha = isha.adjust(to: calculationParameters, prayer: .isha)
        return .init(name: .isha,
                     time: isha)
    }
    
    
}
