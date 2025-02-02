//
//  SunnahTimes.swift
//  AdhanSwift
//
//  Created by ahmad alhayek on 2/2/25.
//

import Foundation

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

public extension SunnahTimes {
    init?(from prayerTimes: PrayerTimes) {
        guard let date = Calendar.gregorianUTC.date(from: prayerTimes.dateComponent),
              let nextDay = Calendar.gregorianUTC.date(byAdding: .day, value: 1, to: date),
              let nextDayPrayerTimes = PrayerTimes(
                  coordinates: prayerTimes.coordinates,
                  date: Calendar.gregorianUTC.dateComponents([.year, .month, .day], from: nextDay),
                  calculationParameters: prayerTimes.calculationParameters
              )
        else {
            // unable to determine tomorrow prayer times
            return nil
        }
        let maghribTime = prayerTimes[.maghrib].prayerTime

        let nightDuration = nextDayPrayerTimes[.fajr].prayerTime.timeIntervalSince(maghribTime)
        middleOfTheNight = maghribTime.addingTimeInterval(nightDuration / 2).roundedMinute()
        lastThirdOfTheNight = maghribTime.addingTimeInterval(nightDuration * (2 / 3)).roundedMinute()
    }
}
