//
//  SolarClockTime.swift
//
//
//  Created by Ahmad Alhayek on 4/24/24.
//

import Foundation
import Time
import SwiftUI

struct SolarClockTime {
    
    let today: Fixed<Day>
    
    let coordinate: Coordinates
    
    let sunsetTime: Fixed<Second>
    let sunriseTime: Fixed<Second>
    let transitTime: Fixed<Second>
    
    let solarCoordinates: SolarCoordinates
    private let prevSolar: SolarCoordinates
    private let nextSolar: SolarCoordinates
    
    private let approxTransit: Double
    init(day: Fixed<Day>, coordinates: Coordinates) throws {
        let julianDay = Astronomical.julianDay(day)
        
        let previousSolar = SolarCoordinates(julianDay: julianDay - 1)
        let currentSolar = SolarCoordinates(julianDay: julianDay)
        let nextSolar = SolarCoordinates(julianDay: julianDay + 1)
        
        let m0 = Astronomical.approximateTransit(longitude: coordinates.longitudeAngle, siderealTime: currentSolar.apparentSiderealTime, rightAscension: currentSolar.rightAscension)
        let solarAltitude = Angle(-50.0 / 60.0)
        
        self.approxTransit = m0
        
        let transitTime = Astronomical.correctedTransit(approximateTransit: m0, longitude: coordinates.longitudeAngle, siderealTime: currentSolar.apparentSiderealTime,
                                                     rightAscension: currentSolar.rightAscension, previousRightAscension: previousSolar.rightAscension, nextRightAscension: nextSolar.rightAscension)
        
        let sunriseTime = Astronomical.correctedHourAngle(approximateTransit: m0, angle: solarAltitude, coordinates: coordinates, afterTransit: false, siderealTime: currentSolar.apparentSiderealTime,
                                                       rightAscension: currentSolar.rightAscension, previousRightAscension: previousSolar.rightAscension, nextRightAscension: nextSolar.rightAscension,
                                                       declination: currentSolar.declination, previousDeclination: previousSolar.declination, nextDeclination: nextSolar.declination)
        
        
        let sunsetTime = Astronomical.correctedHourAngle(approximateTransit: m0, angle: solarAltitude, coordinates: coordinates, afterTransit: true, siderealTime: currentSolar.apparentSiderealTime,
                                                      rightAscension: currentSolar.rightAscension, previousRightAscension: previousSolar.rightAscension, nextRightAscension: nextSolar.rightAscension,
                                                      declination: currentSolar.declination, previousDeclination: previousSolar.declination, nextDeclination: nextSolar.declination)
        
        self.transitTime = try day.settingSeconds(from: transitTime)
        self.sunriseTime = try day.settingSeconds(from: sunriseTime)
        self.sunsetTime = try day.settingSeconds(from: sunsetTime)
        self.coordinate = coordinates
        self.solarCoordinates = currentSolar
        self.nextSolar = nextSolar
        self.prevSolar = previousSolar
        self.today = day
    }
    
    func timeForSolarAngle(_ angle: Angle, afterTransit: Bool) throws -> Fixed<Second> {
        let hours = Astronomical.correctedHourAngle(approximateTransit: approxTransit, angle: angle, coordinates: coordinate, afterTransit: afterTransit, siderealTime: solarCoordinates.apparentSiderealTime,
                                               rightAscension: solarCoordinates.rightAscension, previousRightAscension: prevSolar.rightAscension, nextRightAscension: nextSolar.rightAscension,
                                               declination: solarCoordinates.declination, previousDeclination: prevSolar.declination, nextDeclination: nextSolar.declination)
        return try today.settingHour(hours)
    }

    // hours from transit
    func afternoon(shadowLength: Double) throws -> Fixed<Second> {
        // TODO source shadow angle calculation
        let tangent = Angle(fabs(coordinate.latitude - solarCoordinates.declination.degrees))
        let inverse = shadowLength + tan(tangent.radians)
        let angle = Angle(radians: atan(1.0 / inverse))

        return try timeForSolarAngle(angle, afterTransit: true)
    }
    
}
