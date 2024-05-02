//
//  CalculationMethod.swift
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

/**
 Preset calculation parameters for different regions.

 *Descriptions of the different options*

 **muslimWorldLeague**

 Muslim World League. Standard Fajr time with an angle of 18°. Earlier Isha time with an angle of 17°.

 **egyptian**

 Egyptian General Authority of Survey. Early Fajr time using an angle 19.5° and a slightly earlier Isha time using an angle of 17.5°.

 **karachi**

 University of Islamic Sciences, Karachi. A generally applicable method that uses standard Fajr and Isha angles of 18°.

 **ummAlQura**

 Umm al-Qura University, Makkah. Uses a fixed interval of 90 minutes from maghrib to calculate Isha. And a slightly earlier Fajr time
 with an angle of 18.5°. Note: you should add a +30 minute custom adjustment for Isha during Ramadan.

 **dubai**

 Used in the UAE. Slightly earlier Fajr time and slightly later Isha time with angles of 18.2° for Fajr and Isha in addition to 3 minute
 offsets for sunrise, Dhuhr, Asr, and Maghrib.

 **moonsightingCommittee**

 Method developed by Khalid Shaukat, founder of Moonsighting Committee Worldwide. Uses standard 18° angles for Fajr and Isha in addition
 to seasonal adjustment values. This method automatically applies the 1/7 approximation rule for locations above 55° latitude.
 Recommended for North America and the UK.

 **northAmerica**

 Also known as the ISNA method. Can be used for North America, but the moonsightingCommittee method is preferable. Gives later Fajr times and early
 Isha times with angles of 15°.

 **kuwait**

 Standard Fajr time with an angle of 18°. Slightly earlier Isha time with an angle of 17.5°.

 **qatar**

 Same Isha interval as `ummAlQura` but with the standard Fajr time using an angle of 18°.

 **singapore**

 Used in Singapore, Malaysia, and Indonesia. Early Fajr time with an angle of 20° and standard Isha time with an angle of 18°.

 **tehran**

 Institute of Geophysics, University of Tehran. Early Isha time with an angle of 14°. Slightly later Fajr time with an angle of 17.7°.
 Calculates Maghrib based on the sun reaching an angle of 4.5° below the horizon.

 **turkey**

 An approximation of the Diyanet method used in Turkey. This approximation is less accurate outside the region of Turkey.

 **other**

 Defaults to angles of 0°, should generally be used for making a custom method and setting your own values.

 */

public enum CalculationMethodType: Int, CaseIterable, Codable, Identifiable {
    public var id: RawValue {
        rawValue
    }

    case muslimWorldLeague

    case egyptian

    case karachi

    case ummAlQura

    case dubai

    case moonsightingCommittee

    case northAmerica

    case kuwait

    case qatar

    case singapore

    case tehran

    case turkey

    public var localizedName: LocalizedStringKey {
        switch self {
        case .muslimWorldLeague:
            "Muslim World League"
        case .egyptian:
            "Egyptian"
        case .karachi:
            "Karachi"
        case .ummAlQura:
            "Um Al Qura"
        case .dubai:
            "Dubai"
        case .moonsightingCommittee:
            "Moon-sighting Committee"
        case .northAmerica:
            "North America"
        case .kuwait:
            "Kuwait"
        case .qatar:
            "Qatar"
        case .singapore:
            "Singapore"
        case .tehran:
            "Tehran"
        case .turkey:
            "Turkey"
        }
    }
}

public struct CalculationMethodInput {
    public var calculationMethodType: CalculationMethodType

    public var madhab: Madhab

    public init(calculationMethodType: CalculationMethodType, madhab: Madhab) {
        self.calculationMethodType = calculationMethodType
        self.madhab = madhab
    }

    public var calculationMethod: CalculationMethod {
        switch calculationMethodType {
        case .muslimWorldLeague:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18,
                         ishaAngle: .angle(17),
                         methodTimeAdjustments: PrayerAdjustments(dhuhr: 1),
                         madhab: madhab)
        case .egyptian:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 19.5,
                         ishaAngle: .angle(17.5),
                         methodTimeAdjustments: PrayerAdjustments(dhuhr: 1),
                         madhab: madhab)
        case .karachi:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18,
                         ishaAngle: .angle(18),
                         methodTimeAdjustments: PrayerAdjustments(dhuhr: 1),
                         madhab: madhab)
        case .ummAlQura:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18.5,
                         ishaAngle: .time(90),
                         madhab: madhab)
        case .dubai:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18.2,
                         ishaAngle: .angle(18.2),
                         methodTimeAdjustments: PrayerAdjustments(sunrise: -3, dhuhr: 3, asr: 3, maghrib: 3),
                         madhab: madhab)
        case .moonsightingCommittee:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18,
                         ishaAngle: .angle(18),
                         methodTimeAdjustments: PrayerAdjustments(dhuhr: 5, maghrib: 3),
                         madhab: madhab, isMoonSightingCommittee: true)
        case .northAmerica:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 15,
                         ishaAngle: .angle(15),
                         methodTimeAdjustments: PrayerAdjustments(dhuhr: 1),
                         madhab: madhab)
        case .kuwait:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18,
                         ishaAngle: .angle(17.5),
                         madhab: madhab)
        case .qatar:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18,
                         ishaAngle: .time(90),
                         madhab: madhab)
        case .singapore:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 20,
                         ishaAngle: .angle(18),
                         methodTimeAdjustments: PrayerAdjustments(dhuhr: 1),
                         rounding: .up,
                         madhab: madhab)
        case .tehran:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 17.7,
                         maghribAngle: 4.5,
                         ishaAngle: .angle(14),
                         madhab: madhab)
        case .turkey:
            return .init(name: calculationMethodType.localizedName,
                         fajrAngle: 18,
                         ishaAngle: .angle(17),
                         methodTimeAdjustments: PrayerAdjustments(fajr: 0, sunrise: -7, dhuhr: 5, asr: 4, maghrib: 7, isha: 0),
                         madhab: madhab)
        }
    }
}

public struct CalculationMethod: Equatable {
    public let name: LocalizedStringKey
    public let params: CalculationParameters

    public init(name: LocalizedStringKey, fajrAngle: Double, maghribAngle: Double? = nil,
                ishaAngle: IshaPrayerAdjustments, methodTimeAdjustments: PrayerAdjustments = .init(),
                rounding: Rounding = .nearest, madhab: Madhab = .shafi, shafaq: Shafaq = .general, isMoonSightingCommittee: Bool = false)
    {
        self.name = name

        params = .init(fajrAngle: fajrAngle,
                       maghribAngle: maghribAngle,
                       ishaPrayerAdjustments: ishaAngle,
                       madhab: madhab,
                       highLatitudeRule: nil,
                       adjustments: .init(),
                       rounding: rounding,
                       shafaq: shafaq,
                       methodAdjustments: methodTimeAdjustments,
                       isMoonSightingCommittee: isMoonSightingCommittee)
    }
}
