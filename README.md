## Adahn Swift

A fork of [adahn-swift](https://github.com/batoulapps/adhan-swift) with the use of [Time swift package](https://github.com/davedelong/time)



## Easy to use library 

```swift
let prayerCoordinates = Coordinates(latitude: 42.3601, longitude: -71.0589)
let calculationMethod = CalculationMethodType.northAmerica
let madhab = Madhab.shafi

let calculationInput = CalculationMethodInput(calculationMethodType: calculationMethod, madhab: madhab)

/// PrayerClockTimes handles converting to GTC. you no longer need to give the time in GTC then get it converted to Current
let prayerTimes = try PrayerClockTimes(coordinates: prayerCoordinates,
                                           day: .init(),
                                           method: calculationInput)

let prayers = prayerTimes.prayers
/// Time in GTC
let fajarCTCTime = prayers.first?.time
/// Time in Current calendar
let fajarCurrentTime = try prayers.first?.currentTime

```
