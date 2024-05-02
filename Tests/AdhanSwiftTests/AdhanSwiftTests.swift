//
//  AdhanSwiftTests.swift
//  AdhanTests
//
//  Created byAMeir Al-Zoubi on 2/21/16.
//  Copyright © 2016 Batoul Apps. All rights reserved.
//

@testable import AdhanSwift
import XCTest

func date(year: Int, month: Int, day: Int, hours: Double = 0) -> DateComponents {
    var cal = Calendar(identifier: Calendar.Identifier.gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    var comps = DateComponents()
    (comps as NSDateComponents).calendar = cal
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = Int(hours)
    comps.minute = Int((hours - floor(hours)) * 60)
    return comps
}

extension CalculationParameters {
    init(fajrAngle: Double, ishaAngle: Double) {
        self.init(fajrAngle: fajrAngle, ishaPrayerAdjustments: .angle(ishaAngle))
    }
}

class AdhanTests: XCTestCase {
    func testNightPortion() {
        let coordinates = Coordinates(latitude: 0, longitude: 0)

        var p1 = CalculationParameters(fajrAngle: 18, ishaAngle: 18)
        p1.highLatitudeRule = .middleOfTheNight
        XCTAssertEqual(p1.nightPortions(using: coordinates).fajr, 0.5)
        XCTAssertEqual(p1.nightPortions(using: coordinates).isha, 0.5)

        var p2 = CalculationParameters(fajrAngle: 18, ishaAngle: 18)
        p2.highLatitudeRule = .seventhOfTheNight
        XCTAssertEqual(p2.nightPortions(using: coordinates).fajr, 1 / 7)
        XCTAssertEqual(p2.nightPortions(using: coordinates).isha, 1 / 7)

        var p3 = CalculationParameters(fajrAngle: 10, ishaAngle: 15)
        p3.highLatitudeRule = .twilightAngle
        XCTAssertEqual(p3.nightPortions(using: coordinates).fajr, 10 / 60)
        XCTAssertEqual(p3.nightPortions(using: coordinates).isha, 15 / 60)
    }

    func testCalculationMethods() {
        let p1 = CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p1.fajrAngle, 18)
        XCTAssertEqual(p1.ishaAngle, 17)
        XCTAssertEqual(p1.ishaInterval, 0)

        let p2 = CalculationMethodInput(calculationMethodType: .egyptian, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p2.fajrAngle, 19.5)
        XCTAssertEqual(p2.ishaAngle, 17.5)
        XCTAssertEqual(p2.ishaInterval, 0)

        let p3 = CalculationMethodInput(calculationMethodType: .karachi, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p3.fajrAngle, 18)
        XCTAssertEqual(p3.ishaAngle, 18)
        XCTAssertEqual(p3.ishaInterval, 0)

        let p4 = CalculationMethodInput(calculationMethodType: .ummAlQura, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p4.fajrAngle, 18.5)
        XCTAssertEqual(p4.ishaAngle, 0)
        XCTAssertEqual(p4.ishaInterval, 90)

        let p5 = CalculationMethodInput(calculationMethodType: .dubai, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p5.fajrAngle, 18.2)
        XCTAssertEqual(p5.ishaAngle, 18.2)
        XCTAssertEqual(p5.ishaInterval, 0)

        let p6 = CalculationMethodInput(calculationMethodType: .moonsightingCommittee, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p6.fajrAngle, 18)
        XCTAssertEqual(p6.ishaAngle, 18)
        XCTAssertEqual(p6.ishaInterval, 0)
        assert(p6.isMoonSightingCommittee)

        let p7 = CalculationMethodInput(calculationMethodType: .northAmerica, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p7.fajrAngle, 15)
        XCTAssertEqual(p7.ishaAngle, 15)
        XCTAssertEqual(p7.ishaInterval, 0)

        let p9 = CalculationMethodInput(calculationMethodType: .kuwait, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p9.fajrAngle, 18)
        XCTAssertEqual(p9.ishaAngle, 17.5)
        XCTAssertEqual(p9.ishaInterval, 0)

        let p10 = CalculationMethodInput(calculationMethodType: .qatar, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p10.fajrAngle, 18)
        XCTAssertEqual(p10.ishaAngle, 0)
        XCTAssertEqual(p10.ishaInterval, 90)

        let p11 = CalculationMethodInput(calculationMethodType: .singapore, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p11.fajrAngle, 20)
        XCTAssertEqual(p11.ishaAngle, 18)
        XCTAssertEqual(p11.ishaInterval, 0)

        let p12 = CalculationMethodInput(calculationMethodType: .tehran, madhab: .shafi).calculationMethod.params
        XCTAssertEqual(p12.fajrAngle, 17.7)
        XCTAssertEqual(p12.maghribAngle, 4.5)
        XCTAssertEqual(p12.ishaAngle, 14)
        XCTAssertEqual(p12.ishaInterval, 0)
    }

    func testPrayerTimes() {
        var comps = DateComponents()
        comps.year = 2015
        comps.month = 7
        comps.day = 12
        var params = CalculationMethodInput(calculationMethodType: .northAmerica, madhab: .hanafi).calculationMethod.params
        let p = PrayerTimes(coordinates: Coordinates(latitude: 35.7750, longitude: -78.6336), date: comps, calculationParameters: params)!

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "4:42 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "6:08 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:21 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "6:22 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "8:32 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "9:57 PM")
    }

    func testOffsets() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps = DateComponents()
        comps.year = 2015
        comps.month = 12
        comps.day = 1

        var params = CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params
        if let p = PrayerTimes(coordinates: Coordinates(latitude: 35.7750, longitude: -78.6336), date: comps, calculationParameters: params) {
            XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "5:35 AM")
            XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:06 AM")
            XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:05 PM")
            XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "2:42 PM")
            XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "5:01 PM")
            XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "6:26 PM")
        } else {
            XCTAssert(false)
        }

        params.adjustments.fajr = 10
        params.adjustments.sunrise = 10
        params.adjustments.dhuhr = 10
        params.adjustments.asr = 10
        params.adjustments.maghrib = 10
        params.adjustments.isha = 10
        if let p2 = PrayerTimes(coordinates: Coordinates(latitude: 35.7750, longitude: -78.6336), date: comps, calculationParameters: params) {
            XCTAssertEqual(dateFormatter.string(from: p2[.fajr].prayerTime), "5:45 AM")
            XCTAssertEqual(dateFormatter.string(from: p2[.sunrise].prayerTime), "7:16 AM")
            XCTAssertEqual(dateFormatter.string(from: p2[.dhuhr].prayerTime), "12:15 PM")
            XCTAssertEqual(dateFormatter.string(from: p2[.asr].prayerTime), "2:52 PM")
            XCTAssertEqual(dateFormatter.string(from: p2[.maghrib].prayerTime), "5:11 PM")
            XCTAssertEqual(dateFormatter.string(from: p2[.isha].prayerTime), "6:36 PM")
        } else {
            XCTAssert(false)
        }

        params.adjustments = PrayerAdjustments()
        if let p3 = PrayerTimes(coordinates: Coordinates(latitude: 35.7750, longitude: -78.6336), date: comps, calculationParameters: params) {
            XCTAssertEqual(dateFormatter.string(from: p3[.fajr].prayerTime), "5:35 AM")
            XCTAssertEqual(dateFormatter.string(from: p3[.sunrise].prayerTime), "7:06 AM")
            XCTAssertEqual(dateFormatter.string(from: p3[.dhuhr].prayerTime), "12:05 PM")
            XCTAssertEqual(dateFormatter.string(from: p3[.asr].prayerTime), "2:42 PM")
            XCTAssertEqual(dateFormatter.string(from: p3[.maghrib].prayerTime), "5:01 PM")
            XCTAssertEqual(dateFormatter.string(from: p3[.isha].prayerTime), "6:26 PM")
        } else {
            XCTAssert(false)
        }
    }

    func testMoonsightingMethod() {
        // Values from http://www.moonsighting.com/pray.php
        var comps = DateComponents()
        comps.year = 2016
        comps.month = 1
        comps.day = 31
        let p = PrayerTimes(coordinates: Coordinates(latitude: 35.7750, longitude: -78.6336), date: comps, calculationParameters: CalculationMethodInput(calculationMethodType: .moonsightingCommittee, madhab: .shafi).calculationMethod.params)!

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "5:48 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:16 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:33 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "3:20 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "5:43 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "7:05 PM")
    }

    func testMoonsightingMethodHighLat() {
        // Values from http://www.moonsighting.com/pray.php
        var comps = DateComponents()
        comps.year = 2016
        comps.month = 1
        comps.day = 1
        var params = CalculationMethodInput(calculationMethodType: .moonsightingCommittee, madhab: .shafi).calculationMethod.params
        params.madhab = .hanafi
        let p = PrayerTimes(coordinates: Coordinates(latitude: 59.9094, longitude: 10.7349), date: comps, calculationParameters: params)!

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Oslo")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "7:34 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "9:19 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:25 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "1:36 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "3:25 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "5:02 PM")
    }

    func testTehranMethod() {
        // Values from http://praytimes.org/code/
        var comps = DateComponents()
        comps.year = 2016
        comps.month = 12
        comps.day = 15
        let p = PrayerTimes(coordinates: Coordinates(latitude: 35.715298, longitude: 51.404343), date: comps, calculationParameters: CalculationMethodInput(calculationMethodType: .tehran, madhab: .shafi).calculationMethod.params)!

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "5:37 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:07 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:00 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "2:34 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "5:13 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "6:03 PM")

        var comps2 = DateComponents()
        comps2.year = 2019
        comps2.month = 6
        comps2.day = 16
        let p2 = PrayerTimes(coordinates: Coordinates(latitude: 35.715298, longitude: 51.404343), date: comps2, calculationParameters: CalculationMethodInput(calculationMethodType: .tehran, madhab: .shafi).calculationMethod.params)!

        XCTAssertEqual(dateFormatter.string(from: p2[.fajr].prayerTime), "4:01 AM")
        XCTAssertEqual(dateFormatter.string(from: p2[.sunrise].prayerTime), "5:48 AM")
        XCTAssertEqual(dateFormatter.string(from: p2[.dhuhr].prayerTime), "1:05 PM")
        XCTAssertEqual(dateFormatter.string(from: p2[.asr].prayerTime), "4:54 PM")
        XCTAssertEqual(dateFormatter.string(from: p2[.maghrib].prayerTime), "8:43 PM")
        XCTAssertEqual(dateFormatter.string(from: p2[.isha].prayerTime), "9:43 PM")
    }

    func testDiyanet() {
        // values from https://namazvakitleri.diyanet.gov.tr/en-US/9541/prayer-time-for-istanbul
        let coords = Coordinates(latitude: 41.005616, longitude: 28.976380)
        let params = CalculationMethodInput(calculationMethodType: .turkey, madhab: .shafi).calculationMethod.params

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps1 = DateComponents()
        comps1.year = 2020
        comps1.month = 4
        comps1.day = 16

        let p1 = PrayerTimes(coordinates: coords, date: comps1, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p1[.fajr].prayerTime), "4:44 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.sunrise].prayerTime), "6:16 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.dhuhr].prayerTime), "1:09 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.asr].prayerTime), "4:53 PM") // original time 4:52 PM
        XCTAssertEqual(dateFormatter.string(from: p1[.maghrib].prayerTime), "7:52 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.isha].prayerTime), "9:19 PM") // original time 9:18 PM
    }

    func testEgyptian() {
        let coords = Coordinates(latitude: 30.028703, longitude: 31.249528)
        let params = CalculationMethodInput(calculationMethodType: .egyptian, madhab: .shafi).calculationMethod.params

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Africa/Cairo")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps1 = DateComponents()
        comps1.year = 2020
        comps1.month = 1
        comps1.day = 1

        let p1 = PrayerTimes(coordinates: coords, date: comps1, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p1[.fajr].prayerTime), "5:18 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.sunrise].prayerTime), "6:51 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.dhuhr].prayerTime), "11:59 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.asr].prayerTime), "2:47 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.maghrib].prayerTime), "5:06 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.isha].prayerTime), "6:29 PM")
    }

    func testTimeForPrayer() {
        var comps = DateComponents()
        comps.year = 2016
        comps.month = 7
        comps.day = 1
        var params = CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params
        params.madhab = .hanafi
        params.highLatitudeRule = .twilightAngle
        let p = PrayerTimes(coordinates: Coordinates(latitude: 59.9094, longitude: 10.7349), date: comps, calculationParameters: params)!
        XCTAssertEqual(p[.fajr].prayerTime, p.time(for: .fajr))
        XCTAssertEqual(p[.sunrise].prayerTime, p.time(for: .sunrise))
        XCTAssertEqual(p[.dhuhr].prayerTime, p.time(for: .dhuhr))
        XCTAssertEqual(p[.asr].prayerTime, p.time(for: .asr))
        XCTAssertEqual(p[.maghrib].prayerTime, p.time(for: .maghrib))
        XCTAssertEqual(p[.isha].prayerTime, p.time(for: .isha))
    }

    func testCurrentPrayer() {
        var comps = DateComponents()
        comps.year = 2015
        comps.month = 9
        comps.day = 1
        var params = CalculationMethodInput(calculationMethodType: .karachi, madhab: .shafi).calculationMethod.params
        params.madhab = .hanafi
        params.highLatitudeRule = .twilightAngle
        let p = PrayerTimes(coordinates: Coordinates(latitude: 33.720817, longitude: 73.090032), date: comps, calculationParameters: params)!
        XCTAssertNil(p.currentPrayer(at: p[.fajr].prayerTime.addingTimeInterval(-1)))
        XCTAssertEqual(p.currentPrayer(at: p[.fajr].prayerTime), p[.fajr])
        XCTAssertEqual(p.currentPrayer(at: p[.fajr].prayerTime.addingTimeInterval(1)), p[.fajr])
        XCTAssertEqual(p.currentPrayer(at: p[.sunrise].prayerTime.addingTimeInterval(1)), p[.sunrise])
        XCTAssertEqual(p.currentPrayer(at: p[.dhuhr].prayerTime.addingTimeInterval(1)), p[.dhuhr])
        XCTAssertEqual(p.currentPrayer(at: p[.asr].prayerTime.addingTimeInterval(1)), p[.asr])
        XCTAssertEqual(p.currentPrayer(at: p[.maghrib].prayerTime.addingTimeInterval(1)), p[.maghrib])
        XCTAssertEqual(p.currentPrayer(at: p[.isha].prayerTime.addingTimeInterval(1)), p[.isha])
    }

    func testNextPrayer() {
        var comps = DateComponents()
        comps.year = 2015
        comps.month = 9
        comps.day = 1
        var params = CalculationMethodInput(calculationMethodType: .karachi, madhab: .shafi).calculationMethod.params
        params.madhab = .hanafi
        params.highLatitudeRule = .twilightAngle

        var comps1 = DateComponents()
        comps1.year = 2015
        comps1.month = 8
        comps1.day = 31
        let pp = PrayerTimes(coordinates: Coordinates(latitude: 33.720817, longitude: 73.090032), date: comps1, calculationParameters: params)!

        let p = PrayerTimes(coordinates: Coordinates(latitude: 33.720817, longitude: 73.090032), date: comps, calculationParameters: params)!

        XCTAssertEqual(pp.nextPrayer(at: pp[.isha].prayerTime), p[.fajr])
        XCTAssertEqual(p.nextPrayer(at: p[.fajr].prayerTime), p[.sunrise])
        XCTAssertEqual(p.nextPrayer(at: p[.fajr].prayerTime.addingTimeInterval(1)), p[.sunrise])
        XCTAssertEqual(p.nextPrayer(at: p[.sunrise].prayerTime.addingTimeInterval(1)), p[.dhuhr])
        XCTAssertEqual(p.nextPrayer(at: p[.dhuhr].prayerTime.addingTimeInterval(1)), p[.asr])
        XCTAssertEqual(p.nextPrayer(at: p[.asr].prayerTime.addingTimeInterval(1)), p[.maghrib])
        XCTAssertEqual(p.nextPrayer(at: p[.maghrib].prayerTime.addingTimeInterval(1)), p[.isha])

        comps.day = 2
        let p2 = PrayerTimes(coordinates: Coordinates(latitude: 33.720817, longitude: 73.090032), date: comps, calculationParameters: params)!
        XCTAssertEqual(p.nextPrayer(at: p[.isha].prayerTime.addingTimeInterval(1)), p2[.fajr])
    }

    func testInvalidDate() {
        let comps1 = DateComponents()
        let p1 = PrayerTimes(coordinates: Coordinates(latitude: 33.720817, longitude: 73.090032), date: comps1, calculationParameters: CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params)
        XCTAssertNil(p1)

        var comps2 = DateComponents()
        comps2.year = -1
        comps2.month = 99
        comps2.day = 99
        let p2 = PrayerTimes(coordinates: Coordinates(latitude: 33.720817, longitude: 73.090032), date: comps1, calculationParameters: CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params)
        XCTAssertNil(p2)
    }

    func testInvalidLocation() {
        var comps = DateComponents()
        comps.year = 2019
        comps.month = 1
        comps.day = 1
        let p1 = PrayerTimes(coordinates: Coordinates(latitude: 999, longitude: 999), date: comps, calculationParameters: CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params)
        XCTAssertNil(p1)
    }

    func testExtremeLocation() {
        var comps1 = DateComponents()
        comps1.year = 2018
        comps1.month = 1
        comps1.day = 1
        let p1 = PrayerTimes(coordinates: Coordinates(latitude: 71.275009, longitude: -156.761368), date: comps1, calculationParameters: CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params)
        XCTAssertNil(p1)

        var comps2 = DateComponents()
        comps2.year = 2018
        comps2.month = 3
        comps2.day = 1
        let p2 = PrayerTimes(coordinates: Coordinates(latitude: 71.275009, longitude: -156.761368), date: comps2, calculationParameters: CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params)
        XCTAssertNotNil(p2)
    }

    func testHighLatitudeRule() {
        let coords = Coordinates(latitude: 55.983226, longitude: -3.216649)
        var params = CalculationMethodInput(calculationMethodType: .muslimWorldLeague, madhab: .shafi).calculationMethod.params

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Europe/London")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps1 = DateComponents()
        comps1.year = 2020
        comps1.month = 6
        comps1.day = 15

        params.highLatitudeRule = .middleOfTheNight
        let p1 = PrayerTimes(coordinates: coords, date: comps1, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p1[.fajr].prayerTime), "1:14 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.sunrise].prayerTime), "4:26 AM")
        XCTAssertEqual(dateFormatter.string(from: p1[.dhuhr].prayerTime), "1:14 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.asr].prayerTime), "5:46 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.maghrib].prayerTime), "10:01 PM")
        XCTAssertEqual(dateFormatter.string(from: p1[.isha].prayerTime), "1:14 AM")

        params.highLatitudeRule = .seventhOfTheNight
        let p2 = PrayerTimes(coordinates: coords, date: comps1, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p2[.fajr].prayerTime), "3:31 AM")
        XCTAssertEqual(dateFormatter.string(from: p2[.sunrise].prayerTime), "4:26 AM")
        XCTAssertEqual(dateFormatter.string(from: p2[.dhuhr].prayerTime), "1:14 PM")
        XCTAssertEqual(dateFormatter.string(from: p2[.asr].prayerTime), "5:46 PM")
        XCTAssertEqual(dateFormatter.string(from: p2[.maghrib].prayerTime), "10:01 PM")
        XCTAssertEqual(dateFormatter.string(from: p2[.isha].prayerTime), "10:56 PM")

        params.highLatitudeRule = .twilightAngle
        let p3 = PrayerTimes(coordinates: coords, date: comps1, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p3[.fajr].prayerTime), "2:31 AM")
        XCTAssertEqual(dateFormatter.string(from: p3[.sunrise].prayerTime), "4:26 AM")
        XCTAssertEqual(dateFormatter.string(from: p3[.dhuhr].prayerTime), "1:14 PM")
        XCTAssertEqual(dateFormatter.string(from: p3[.asr].prayerTime), "5:46 PM")
        XCTAssertEqual(dateFormatter.string(from: p3[.maghrib].prayerTime), "10:01 PM")
        XCTAssertEqual(dateFormatter.string(from: p3[.isha].prayerTime), "11:50 PM")

        params.highLatitudeRule = nil
        let pAuto = PrayerTimes(coordinates: coords, date: comps1, calculationParameters: params)!
        let expectedAuto = p2

        XCTAssertEqual(pAuto[.fajr].prayerTime, expectedAuto[.fajr].prayerTime)
        XCTAssertEqual(pAuto[.sunrise].prayerTime, expectedAuto[.sunrise].prayerTime)
        XCTAssertEqual(pAuto[.dhuhr].prayerTime, expectedAuto[.dhuhr].prayerTime)
        XCTAssertEqual(pAuto[.asr].prayerTime, expectedAuto[.asr].prayerTime)
        XCTAssertEqual(pAuto[.maghrib].prayerTime, expectedAuto[.maghrib].prayerTime)
        XCTAssertEqual(pAuto[.isha].prayerTime, expectedAuto[.isha].prayerTime)
    }

    func testRecommendedHighLatitudeRule() {
        let coords1 = Coordinates(latitude: 45.983226, longitude: -3.216649)
        XCTAssertEqual(HighLatitudeRule.recommended(for: coords1), .middleOfTheNight)

        let coords2 = Coordinates(latitude: 48.983226, longitude: -3.216649)
        XCTAssertEqual(HighLatitudeRule.recommended(for: coords2), .seventhOfTheNight)
    }

    func testShafaqGeneral() {
        let coords = Coordinates(latitude: 43.494, longitude: -79.844)
        var params = CalculationMethodInput(calculationMethodType: .moonsightingCommittee, madhab: .shafi).calculationMethod.params
        params.shafaq = .general
        params.madhab = .hanafi

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps = DateComponents()
        comps.year = 2021
        comps.month = 1
        comps.day = 1

        var p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "6:16 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:52 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "3:12 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "4:57 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "6:27 PM")

        comps.year = 2021
        comps.month = 4
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "5:28 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:01 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "5:53 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "7:49 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "9:01 PM")

        comps.year = 2021
        comps.month = 7
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "3:52 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "5:42 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "6:42 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "9:07 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "10:22 PM")

        comps.year = 2021
        comps.month = 11
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "6:22 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:55 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:08 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "4:26 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "6:13 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "7:35 PM")
    }

    func testShafaqAhmer() {
        let coords = Coordinates(latitude: 43.494, longitude: -79.844)
        var params = CalculationMethodInput(calculationMethodType: .moonsightingCommittee, madhab: .shafi).calculationMethod.params
        params.shafaq = .ahmer

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps = DateComponents()
        comps.year = 2021
        comps.month = 1
        comps.day = 1

        var p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "6:16 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:52 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "2:37 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "4:57 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "6:07 PM") // value from source is 6:08 PM

        comps.year = 2021
        comps.month = 4
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "5:28 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:01 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "4:59 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "7:49 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "8:45 PM")

        comps.year = 2021
        comps.month = 7
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "3:52 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "5:42 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "5:29 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "9:07 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "10:19 PM")

        comps.year = 2021
        comps.month = 11
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "6:22 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:55 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:08 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "3:45 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "6:13 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "7:15 PM")
    }

    func testShafaqAbyad() {
        let coords = Coordinates(latitude: 43.494, longitude: -79.844)
        var params = CalculationMethodInput(calculationMethodType: .moonsightingCommittee, madhab: .shafi).calculationMethod.params
        params.shafaq = .abyad
        params.madhab = .hanafi

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        var comps = DateComponents()
        comps.year = 2021
        comps.month = 1
        comps.day = 1

        var p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "6:16 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:52 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "12:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "3:12 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "4:57 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "6:28 PM")

        comps.year = 2021
        comps.month = 4
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "5:28 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:01 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "5:53 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "7:49 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "9:12 PM")

        comps.year = 2021
        comps.month = 7
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "3:52 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "5:42 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:28 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "6:42 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "9:07 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "11:17 PM")

        comps.year = 2021
        comps.month = 11
        comps.day = 1
        p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params)!

        XCTAssertEqual(dateFormatter.string(from: p[.fajr].prayerTime), "6:22 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.sunrise].prayerTime), "7:55 AM")
        XCTAssertEqual(dateFormatter.string(from: p[.dhuhr].prayerTime), "1:08 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.asr].prayerTime), "4:26 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.maghrib].prayerTime), "6:13 PM")
        XCTAssertEqual(dateFormatter.string(from: p[.isha].prayerTime), "7:37 PM")
    }
}
