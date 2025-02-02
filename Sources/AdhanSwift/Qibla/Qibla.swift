//
//  Qibla.swift
//  AdhanSwift
//
//  Created by ahmad alhayek on 2/2/25.
//

import Foundation
import SwiftUICore

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
