//
//  Double+Extension.swift
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
import CoreLocation
import SwiftUI

// MARK: Double
internal extension Double {

    func normalizedToScale(_ max: Double) -> Double {
        return self - (max * (floor(self / max)))
    }
}

// MARK: CLLocationCoordinate2D

public typealias Coordinates = CLLocationCoordinate2D

extension CLLocationCoordinate2D {
    var latitudeAngle: Angle {
        return Angle(latitude)
    }
    
    var longitudeAngle: Angle {
        return Angle(longitude)
    }
}

// MARK: Angle

extension Angle {
    init(_ degrees: Double) {
        self.init(degrees: degrees)
    }
    
    func unwound() -> Angle {
        return Angle(degrees.normalizedToScale(360))
    }
    
    func quadrantShifted() -> Angle {
        if degrees >= -180 && degrees <= 180 {
            return self
        }
        
        return Angle(degrees - (360 * (degrees/360).rounded()))
    }
}

func +(left: Angle, right: Angle) -> Angle {
    Angle(left.degrees + right.degrees)
}

func -(left: Angle, right: Angle) -> Angle {
    Angle(left.degrees - right.degrees)
}

func *(left: Angle, right: Angle) -> Angle {
    Angle(left.degrees * right.degrees)
}

func /(left: Angle, right: Angle) -> Angle {
    Angle(left.degrees / right.degrees)
}

public typealias Minute = Int64

extension Minute {
    /// value in seconds
    var timeInterval: TimeInterval {
        TimeInterval(self * 60)
    }
}
