//
//  extension+time.swift
//
//
//  Created by Ahmad Alhayek on 4/24/24.
//

import Foundation
import Time

extension Fixed where Granularity == Second {
    func adjust(to calculationParameters: CalculationParameters, prayer: Prayer.Name) -> Fixed<Second> {
        let rounding = calculationParameters.rounding.roundingDirection
        return switch prayer {
        case .fajr:
            adding(seconds: Int(calculationParameters.adjustments.fajr.timeInterval))
                .adding(seconds: Int(calculationParameters.methodAdjustments.fajr.timeInterval))
                .roundedToMinute(direction: rounding)
        case .sunrise:
            adding(seconds: Int(calculationParameters.adjustments.sunrise.timeInterval))
                .adding(seconds: Int(calculationParameters.methodAdjustments.sunrise.timeInterval))
                .roundedToMinute(direction: rounding)
        case .dhuhr:
            adding(seconds: Int(calculationParameters.adjustments.dhuhr.timeInterval))
                .adding(seconds: Int(calculationParameters.methodAdjustments.dhuhr.timeInterval))
                .roundedToMinute(direction: rounding)
        case .asr:
            adding(seconds: Int(calculationParameters.adjustments.asr.timeInterval))
                .adding(seconds: Int(calculationParameters.methodAdjustments.asr.timeInterval))
                .roundedToMinute(direction: rounding)
        case .maghrib:
            adding(seconds: Int(calculationParameters.adjustments.maghrib.timeInterval))
                .adding(seconds: Int(calculationParameters.methodAdjustments.maghrib.timeInterval))
                .roundedToMinute(direction: rounding)
        case .isha:
            adding(seconds: Int(calculationParameters.adjustments.isha.timeInterval))
                .adding(seconds: Int(calculationParameters.methodAdjustments.isha.timeInterval))
                .roundedToMinute(direction: rounding)
        }
    }
}

extension Fixed where Granularity == Day {
    func settingSeconds(from astronomicalTime: Double) throws -> Fixed<Second> {
        guard astronomicalTime.isNormal else {
            throw PrayerTimesError.astronomicalTimeMustBeNormal
        }

        let calculatedHours = floor(astronomicalTime)
        let calculatedMinutes = floor((astronomicalTime - calculatedHours) * 60)
        let calculatedSeconds = floor((astronomicalTime - (calculatedHours + calculatedMinutes / 60)) * 60 * 60)

        let hour = Int(calculatedHours)
        let minute = Int(calculatedMinutes)
        let second = Int(calculatedSeconds)

        return try setting(hour: hour == 24 ? 0 : hour, minute: minute, second: second)
    }

    private func convertToTimeComponents(from hours: Double) -> (hour: Int, minute: Int, second: Int) {
        let totalSeconds = Int(hours * 3600)
        let hour = totalSeconds / 3600
        let minute = (totalSeconds % 3600) / 60
        let second = (totalSeconds % 3600) % 60
        return (hour, minute, second)
    }

    func settingHour(_ hour: Double) throws -> Fixed<Second> {
        if hour >= 24.0 {
            let day = nextDay
            let newHour = hour - 24.0
            let (h, m, s) = convertToTimeComponents(from: newHour)
            return try day.setting(hour: h, minute: m, second: s)
        }
        let (h, m, s) = convertToTimeComponents(from: hour)
        return try setting(hour: h, minute: m, second: s)
    }
}

// MARK: conventional

public extension Fixed where Granularity == Second {
    /// Converted to date
    var date: Date {
        firstInstant.date
    }
}

public extension Fixed where Granularity == Day {
    /// Returns a `Fixed<Day>` initialized to the current date and time.
    init() {
        self.init(region: .current, date: Date())
    }
}
