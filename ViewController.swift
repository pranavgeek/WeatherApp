//
//  ViewController.swift
//  Lab03
//
//  Created by Pranav Geek on 2023-11-14.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {
    
    var cityWeatherArray: [CityWeather] = []
    
    let locationManager = CLLocationManager()
    var locationDelegate: MyLocationDelegate!
    var isCelsius: Bool = true
    private var TableViewPage = "goToTableViewPage"
    @IBOutlet weak var searchValue: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var LocationLabel: UILabel!
    @IBOutlet weak var WeatherconditionLabel: UILabel!
    @IBOutlet weak var weatherConditionImg: UIImageView!
    

    let conditionCodeMapping: [Int: String] = [
        1000: "Sunny",
        1003: "Partly cloudy",
        1006: "Cloudy",
        1009: "Overcast",
        1030: "Mist",
        1063: "Patchy rain possible",
        1066: "Patchy snow possible",
        1069: "Patchy sleet possible",
        1072: "Patchy freezing drizzle possible",
        1087: "Thundery outbreaks possible",
        1114: "Blowing snow",
        1117: "Blizzard",
        1135: "Fog",
        1147: "Freezing fog",
        1150: "Patchy light drizzle",
        1153: "Light drizzle",
        1168: "Freezing drizzle",
        1171: "Heavy freezing drizzle",
        1180: "Patchy light rain",
        1183: "Light rain",
        1186: "Moderate rain at times",
        1189: "Moderate rain",
        1192: "Heavy rain at times",
        1195: "Heavy rain",
        1198: "Light freezing rain",
        1201: "Moderate or heavy freezing rain",
        1204: "Light sleet",
        1207: "Moderate or heavy sleet",
        1210: "Patchy light snow",
        1213: "Light snow",
        1216: "Patchy moderate snow",
        1219: "Moderate snow",
        1222: "Patchy heavy snow",
        1225: "Heavy snow",
        1237: "Ice pellets",
        1240: "Light rain shower",
        1243: "Moderate or heavy rain shower",
        1246: "Torrential rain shower",
        1249: "Light sleet showers",
        1252: "Moderate or heavy sleet showers",
        1255: "Light snow showers",
        1258: "Moderate or heavy snow showers",
        1261: "Light showers of ice pellets",
        1264: "Moderate or heavy showers of ice pellets",
        1273: "Patchy light rain with thunder",
        1276: "Moderate or heavy rain with thunder",
        1279: "Patchy light snow with thunder",
        1282: "Moderate or heavy snow with thunder"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchValue.delegate = self
        locationDelegate = MyLocationDelegate(viewController: self)
        locationManager.delegate = locationDelegate
        
    }
    

    private func displayImg(conditionCode: Int, isDay: Int) {
        WeatherImageUtility.displayImg(in: weatherConditionImg, conditionCode: conditionCode, isDay: isDay)
    }
    
   // Function that's toggle Celsius to Fahrenheit and vice-versa
    @IBAction func temperatureToggle(_ sender: UISwitch) {

        if sender.isOn == false {
                self.locationDelegate.isCelsius = true
            } else {
                self.locationDelegate.isCelsius = false
            }

            if let weatherData = self.locationDelegate.lastWeatherData {
                self.locationDelegate.updateTemperatureDisplay(with: weatherData)
            }
    }
    
    // Location Button Functionality
    func fetchWeatherDataForCurrentLocation(latitude: Double, longitude: Double) {
            let apiKey = "9a82034ea168436992f224722231511"
            let currentEndPoint = "current.json"
            let baseUrl = "https://api.weatherapi.com/v1/"
            let urlString = "\(baseUrl)\(currentEndPoint)?key=\(apiKey)&q=\(latitude), \(longitude)"

            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            let session = URLSession.shared
            let dataTask = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data received")
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let weatherData = try decoder.decode(WeatherData.self, from: data)
                    
                    let isDay = weatherData.current.is_day
                    
                    let conditionCode = weatherData.current.condition.code
                    
                    if let conditionDescription = self.conditionCodeMapping[conditionCode] {
                        DispatchQueue.main.async {
                               self.WeatherconditionLabel.text = conditionDescription
                            self.displayImg(conditionCode: conditionCode, isDay: isDay)
                               print("Weather condition: \(conditionDescription)")
                           }
                    } else {
                        print("Unknown condition code: \(conditionCode)")
                    }

                    DispatchQueue.main.async {
                        self.LocationLabel.text = weatherData.location.name
                        self.tempLabel.text = "\(weatherData.current.temp_c)°C"
                        self.locationDelegate.updateTemperatureDisplay(with: weatherData)
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }

            dataTask.resume()
        }
    
    // Search Button Functionality
    func fetchWeatherData(forQuery query: String) {

        guard let url = getURL(query: query) else {
            print("Didn't get the URL")
            return
        }

        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            print("Call completed")

            guard error == nil else {
                print("Got an error: \(error!)")
                return
            }

            guard let data = data else {
                print("No data")
                return
            }

            if let weatherData = self.parseJSON(data: data) {
                let tempV: String = "\(String(weatherData.current.temp_c))°C"
                print(weatherData.location.name)
                print(weatherData.current.temp_c)
                print(weatherData.current.temp_f)
                print(weatherData.current.condition.code)
                print(weatherData.current.is_day)

                let isDay = weatherData.current.is_day
                let conditionCode = weatherData.current.condition.code

                if let conditionDescription = self.conditionCodeMapping[conditionCode] {
                    DispatchQueue.main.async {
                        self.WeatherconditionLabel.text = conditionDescription
                        self.displayImg(conditionCode: conditionCode, isDay: isDay)
                        print("Weather condition: \(conditionDescription)")
                    }
                } else {
                    print("Unknown condition code: \(conditionCode)")
                }

                DispatchQueue.main.async {
                    self.LocationLabel.text = weatherData.location.name
                    self.tempLabel.text = tempV

                    let cityWeather = CityWeather(
                        cityName: weatherData.location.name,
                        temperature: self.locationDelegate.isCelsius ? weatherData.current.temp_c : weatherData.current.temp_f,
                        isCelsius: self.locationDelegate.isCelsius,
                        weatherCondition: weatherData.current.condition.text,
                        icon: conditionCode
                    )

                    self.cityWeatherArray.append(cityWeather)
                    self.locationDelegate.updateTemperatureDisplay(with: weatherData)
                }
            }
        }

        dataTask.resume()
    }

    
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fetchWeatherData(forQuery: textField.text ?? "")
        textField.endEditing(true)
        return true
    }
    
    // IBAction for location button
    @IBAction func locationPressed(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
    }
    
    // IBAction for search button
    @IBAction func searchPressed(_ sender: UIButton) {
        fetchWeatherData(forQuery: searchValue.text ?? "")
        searchValue.resignFirstResponder()
    }
    
    //Navigation Func
    private func navigateToTableView() {
        performSegue(withIdentifier: TableViewPage, sender: self)
    }
    
    @IBAction func CitiesBtn(_ sender: UIButton) {
        navigateToTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? CitiesTableViewController {
            destinationVC.cityWeatherArray = self.cityWeatherArray
        }
    }
    
    
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let API_Key = "9a82034ea168436992f224722231511"
        if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
               let urlString = "\(baseUrl)\(currentEndPoint)?key=\(API_Key)&q=\(encodedQuery)"
               print(urlString)
               return URL(string: urlString)
           } else {
               print("Failed to encode the query")
               return nil
           }
    }
    
    private func parseJSON(data: Data) -> WeatherData? {
        let decoder = JSONDecoder()
        var weather: WeatherData?
        
        do {
            weather = try decoder.decode(WeatherData.self, from: data)
            print("weather")
        } catch let error {
            print("Error decoding JSON: \(error)")
        }
        return weather
    }
    
}

struct WeatherData: Decodable {
    let location: LocationClimate
    let current: Weather
}

struct LocationClimate: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let is_day: Int
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}

struct CityWeather {
    let cityName: String
    let temperature: Float
    let isCelsius: Bool
    let weatherCondition: String
    let icon: Int
}


class MyLocationDelegate: NSObject, CLLocationManagerDelegate {
    
    weak var viewController: ViewController?
    var isCelsius: Bool = true
    var lastWeatherData: WeatherData?

        init(viewController: ViewController) {
            self.viewController = viewController
            super.init()
        }
    
    func updateTemperatureDisplay(with weatherData: WeatherData) {
           lastWeatherData = weatherData

           var temperature: Float
        var temperatureUnit: String

           if isCelsius {
               temperature = weatherData.current.temp_c
               temperatureUnit = "°C"

           } else {
               temperature = weatherData.current.temp_f
               temperatureUnit = "°F"
               
           }

            let temperatureString = String(format: "%.1f", temperature)
            self.viewController?.tempLabel.text = "\(temperatureString)\(temperatureUnit)"
       }
    
    func getLatLon(latitude: Double, longitude: Double) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let API_Key = "9a82034ea168436992f224722231511"
        let query = "\(latitude), \(longitude)"
        if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
               let urlString = "\(baseUrl)\(currentEndPoint)?key=\(API_Key)&q=\(encodedQuery)"
               print(urlString)
               return URL(string: urlString)
           } else {
               print("Failed to encode the query")
               return nil
           }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            if let url = getLatLon(latitude: lat, longitude: lon) {
                print(url)
            }
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) {(placemarks, error) in
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    return
                }
                if let placeMark = placemarks?.first {
                    let city = placeMark.locality ?? ""
                    print("City: \(city)")
                    
                    DispatchQueue.main.async {
                    self.viewController?.LocationLabel.text = city
                    self.viewController?.fetchWeatherDataForCurrentLocation(latitude: lat, longitude: lon)
                    }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
}


class WeatherImageUtility {
    static func displayImg(in imageView: UIImageView, conditionCode: Int, isDay: Int) {
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .systemOrange] )
        
        switch conditionCode {
            
        case 1000:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "sun.max.circle")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "moon.circle")
                print("its a night")
            }
        case 1003:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sun.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.fill")
            }
        case 1006:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.circle")
            }
        case 1009:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.circle")
        case 1030:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.fog.fill")
        case 1063:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sun.rain.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.rain")
            }
        case 1066:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "sun.snow.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.rain")
            }
        case 1069:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sleet.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "moon.dust.fill")
            }
        case 1072:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.drizzle.fill")
        case 1087:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sun.bolt.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.bolt.fill")
            }
        case 1114:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.fill")
        case 1117:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow")
        case 1135:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.fog.circle.fill")
        case 1147:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.fog.circle")
        case 1150:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.drizzle")
        case 1153:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.drizzle.circle")
        case 1168:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.drizzle.fill")
        case 1171:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.drizzle.circle.fill")
        case 1180:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.rain.fill")
        case 1183:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.rain.circle.fill")
        case 1186:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.rain.circle")
        case 1189:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.rain")
        case 1192:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.heavyrain.fill")
        case 1195:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.heavyrain.circle.fill")
        case 1198:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.rain")
        case 1201:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.heavyrain.circle")
        case 1204:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.sleet.circle")
        case 1207:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.sleet")
        case 1210:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "sun.snow.circle")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "moon.dust.circle")
            }
        case 1213:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle.fill")
        case 1216:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle")
        case 1219:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle.fill")
        case 1222:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow")
        case 1225:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.fill")
        case 1237:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle")
        case 1240:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sun.rain.circle.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.rain")
            }
        case 1243:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sun.rain.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.rain.circle")
            }
        case 1246:
            if isDay == 1 {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.sun.bolt.fill")
            }else {
                imageView.preferredSymbolConfiguration = config
                imageView.image = UIImage(systemName: "cloud.moon.bolt.fill")
            }
        case 1249:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.sleet.circle")
        case 1252:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.sleet.fill")
        case 1255:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle.fill")
        case 1258:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow")
        case 1261:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle")
        case 1264:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.fill")
        case 1273:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.bolt.rain.fill")
        case 1276:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.bolt.rain.circle.fill")
        case 1279:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle")
        case 1282:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "cloud.snow.circle.fill")
            
        default:
            imageView.preferredSymbolConfiguration = config
            imageView.image = UIImage(systemName: "questionmark")
        }
        
    }
}
