//
//  SalahTimeView.swift
//
//
//  Created by Ahmad Alhayek on 4/24/24.
//

import SwiftUI
import AdhanSwift
import Time

struct SalahTimeView: View {
    let coordinates = Coordinates(latitude: 42.3601, longitude: -71.0589)
    
    @State var calculationMethod = CalculationMethodType.northAmerica
    
    @State var madhab = Madhab.shafi
    
    private var calculationMethodInput: CalculationMethodInput {
        CalculationMethodInput(calculationMethodType: calculationMethod, madhab: madhab)
    }
    
    var body: some View {
        if let prayerTimes = try? PrayerClockTimes(coordinates: coordinates,
                                                   day: .init(),
                                                   method: calculationMethodInput) {
            VStack {
                ForEach(prayerTimes.prayers, id: \.name) {
                    let name = $0.name
                    if let time = try? $0.currentTime.date {
                        HStack {
                            Text(name.rawValue)
                            Spacer()
                            Text(time, style: .time)
                        }
                        .padding(.horizontal)
                        .font(.title3)
                        .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Picker("Madhab", selection: $madhab) {
                        ForEach(Madhab.allCases) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    Spacer()
                    
                    Picker("Method", selection: $calculationMethod) {
                        ForEach(CalculationMethodType.allCases) {
                            Text($0.localizedName)
                                .tag($0)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SalahTimeView()
}

