import UIKit

class CitiesTableViewController: UIViewController, UITableViewDataSource {

    var cityWeatherArray: [CityWeather] = []

    @IBOutlet weak var cityTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let tableView = cityTableView else {
            fatalError("cityTableView outlet not connected")
        }

        tableView.dataSource = self
        tableView.reloadData()
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityWeatherArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityLists", for: indexPath)

        let cityWeather = cityWeatherArray[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = cityWeather.cityName
        content.secondaryText = "\(cityWeather.temperature)°" + (cityWeather.isCelsius ? "C" : "F") + "\n" + "\(cityWeather.weatherCondition)"
        cell.contentConfiguration = content
        
        let imageView = UIImageView()

        let conditionCode = cityWeather.icon
        WeatherImageUtility.displayImg(in: imageView, conditionCode: conditionCode, isDay: 1)  // Assuming isDay value is 1, modify as needed

        imageView.contentMode = .scaleAspectFit
        cell.accessoryView = imageView

        return cell
    }

    @IBAction func dismiss(_ sender: UIButton) {
        print("hello")
        dismiss(animated: true, completion: nil)
    }
    

}
