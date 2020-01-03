//
//  TableViewController.swift
//  JournalApp
//
//  Created by David Brannen on 12/5/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import UIKit
import CoreData


class TableViewController: UITableViewController {
    
    let cellId = "Cell"
    var items: [NSManagedObject] = []
    let persistenceManager: PersistenceManager
    init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        persistenceManager = PersistenceManager.shared
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Entries"
//        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        NotificationCenter.default.addObserver(self, selector: #selector(notificationWeatherReady(notification:)), name: Notifications.notificationWeatherReady, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /// loads any offline data & reloads the UI
        fetchData()
        /// downloads weather data from your remote & reloads UI
        fetchWeather()
    }
    
    func fetchData() {
        let sort = NSSortDescriptor(key: #keyPath(Item.timestamp), ascending: true)
        items = persistenceManager.fetch(Item.self, sort: sort)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
//    var viewModel: ViewModel?
    func fetchWeather() {
        items = self.fetchWeather2MoveLater(items: items)
        //        items = viewModel?.fetchWeather(items: items) ?? []
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    @objc func notificationWeatherReady(notification: Notification) {
        print("note recieved")
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func fetchWeather2MoveLater(items: [NSManagedObject]) -> [NSManagedObject] {
        for index in items.indices {
            var locationNumber = "2357024"
            var wDate = items[index].value(forKeyPath: "date") as! String
            wDate = convertDateFormater(wDate)
///get location number
            if let wCity = items[index].value(forKeyPath: "city") as? String {
                locationNumber = getLocationNumber(city: wCity.lowercased())
                print("got", locationNumber, "from", wCity.lowercased())
            }
///use location number
            var request = "https://www.metaweather.com/api/location/" + locationNumber + "/"
            request = request  + wDate + "/"
            guard let url = URL(string: request) else {return items}
            let session = URLSession.shared
            let dataTask = session.dataTask(with: url) { (data, response, error) in
                if error != nil { print(error!); return}
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    print(response!)
                    return
                }
                if let data = data {
                    let decoder = JSONDecoder()
                    do {
/// once data is received & serialized, place within structure
                        var arrayOfCityDayWeathers: Array<CityDayWeather>
                        arrayOfCityDayWeathers = try decoder.decode([CityDayWeather].self, from: data)
                        if let item = items[index] as? Item {
                            if arrayOfCityDayWeathers.count > 0 {
                                item.weather_state_name = arrayOfCityDayWeathers[0].weather_state_name
                            }
                        }
                    } catch let error {
                        print("Parsing Failed \(error.localizedDescription)")
                    }
                }
            }
            dataTask.resume()
        }
        NotificationCenter.default.post(name: Notifications.notificationWeatherReady, object: nil)
        return items
    }
    func convertDateFormater(_ date: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM/dd/yy"
        let dateDate = dateFormatterGet.date(from: date)!
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy/MM/dd"
        return dateformat.string(from: dateDate)
    }
    func getLocationNumber(city: String) -> String {
        if city == "2357024" {return "2357024"}
        var cityNumber = "2357024"
        let request = "https://www.metaweather.com/api/location/search/?query=" + city
        guard let url = URL(string: request) else {return cityNumber}
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { (data, response, error) in
            if error != nil { print(error!); return}
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print(response!)
                return
            }
            if let data = data {
                let decoder = JSONDecoder()
                do {
/// once data is received & serialized, return with locationNumber = cityNumber
                    var WeatherCity: Array<CityForWeather>
                    WeatherCity = try decoder.decode([CityForWeather].self, from: data)
                    if WeatherCity.count > 0 {
                        cityNumber = String (WeatherCity[0].woeid)
                        print("found", cityNumber)
                    }
                } catch let error {
                    print("Parsing Failed \(error.localizedDescription)")
                }
            }
        }
        dataTask.resume()
        return cityNumber
    }
    
}



extension TableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> JournalCell {
        let item = items[indexPath.row] as! Item
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! JournalCell
        var timeStamp: String = ""
        if let date = item.date, let time = item.time {
            timeStamp = "Added \(date) at \(time)"
        }
        cell.entryLabel.text     = item.entry
        cell.timeLabel.text      = timeStamp
        cell.weatherState.text   = item.weather_state_name
        cell.occurrenceDate.text = item.occuranceDate
        cell.city.text           = item.city
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            
            let item = self.items[indexPath.row]
            PersistenceManager.shared.context.delete(item)
            self.items.remove(at: indexPath.row)
            PersistenceManager.shared.save()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        return swipeActions
    }
}
