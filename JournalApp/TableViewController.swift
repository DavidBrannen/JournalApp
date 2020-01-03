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
        self.tableView.rowHeight = UITableView.automaticDimension
        NotificationCenter.default.addObserver(self, selector: #selector(notificationWeatherReady(notification:)), name: Notifications.notificationWeatherReady, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /// loads any offline data & reloads the UI
        fetchData()
        
        let syncQueue = DispatchQueue(label: "syncWeatherQueue")
        //        syncQueue.sync {
        ///update cityNumber
        syncQueue.sync {[weak self] in
            guard let self = self else {return}
            self.updateCityNumber()
            print("city Number")
        }
        ///update urlWeatherCityNumberDate
        syncQueue.sync {[weak self] in
            guard let self = self else {return}
            self.updateURLWeatherCityNumberDate()
            print("url")
        }
        /// downloads weather data from your remote & reloads UI
        syncQueue.sync {[weak self] in
            guard let self = self else {return}
            self.fetchWeather()
            print("Weather")
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            print("complete")
        }
    }
    
    func fetchData() {
        let sort = NSSortDescriptor(key: #keyPath(Item.timestamp), ascending: true)
        items = persistenceManager.fetch(Item.self, sort: sort)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func updateCityNumber () {
        for index in items.indices {
            if let wCity = (items[index].value(forKeyPath: "city") as? String)?.lowercased(){
                var cityNum = "2357024" //default
                let requestCity = "https://www.metaweather.com/api/location/search/?query=" + wCity
                guard let url = URL(string: requestCity) else {return}
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
                            var WeatherCity: Array<CityForWeather>
                            cityNum = "400"
                            /// once data is received & serialized, return with locationNumber = cityNumber
                            WeatherCity = try decoder.decode([CityForWeather].self, from: data)
                            if WeatherCity.count > 0 {
                                cityNum = String(WeatherCity[0].woeid)
                            }
                            self.items[index].setValue(cityNum, forKey: "cityNumber")
                            print(index, cityNum)
                        } catch let error {
                            print("Parsing Failed \(error.localizedDescription)")
                        }
                    }
                }
                dataTask.resume()
                print ("resume got ciy")
            }
            
            var wDate = items[index].value(forKeyPath: "date") as! String
            wDate = convertDateFormater(wDate)
            if items[index].value(forKey: "occurrenceDate") != nil {
                wDate = (items[index].value(forKey: "occurrenceDate") as? String)!
                wDate = convertDateFormater(wDate)
                items[index].setValue(wDate, forKey: "occurrenceDate")
            }
        }
    }
    func updateURLWeatherCityNumberDate() {
        for index in items.indices {
            var cityNum: String
            if  (items[index].value(forKey: "cityNumber") != nil) {
                cityNum = items[index].value(forKey: "cityNumber") as! String
            } else {
                cityNum = "2357024"
            }
            var oDate: String
            if items[index].value(forKey: "occurrenceDate") != nil {
                oDate = items[index].value(forKey: "occurrenceDate") as! String
            } else {
                oDate = (items[index].value(forKey: "date") as? String)!
                oDate = convertDateFormater(oDate)
            }
            var urlWeather = "https://www.metaweather.com/api/location/" + cityNum
            urlWeather = urlWeather + "/" + oDate + "/"
            items[index].setValue(urlWeather, forKey: "urlWeatherCityNumberDate")
//            print(index, urlWeather, items[index].value(forKey: "city"))
        }
        print ("added urls")

    }
    @objc func notificationWeatherReady(notification: Notification) {
        print("note recieved")
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func fetchWeather() {
        for index in items.indices {
            //use request
            let request = items[index].value(forKey: "urlWeatherCityNumberDate") as! String
            guard let url = URL(string: request) else {return }
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
                        if arrayOfCityDayWeathers.count > 0 {
                            let state = arrayOfCityDayWeathers[0].weather_state_name
                            self.items[index].setValue(state, forKey: "weather_state_name")
//                            print(index ,state)
                        }
                    } catch let error {
                        print("Parsing Failed \(error.localizedDescription)")
                    }
                }
            }
            dataTask.resume()
        }
        NotificationCenter.default.post(name: Notifications.notificationWeatherReady, object: nil)
    }
    func convertDateFormater(_ date: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM/dd/yy"
        let dateDate = dateFormatterGet.date(from: date) ?? Date()
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy/MM/dd"
        return dateformat.string(from: dateDate)
    }
    func getDayWeatherURL(city: String, wDate: String) -> String {
        var returnValue = "https://www.metaweather.com/api/location/" + city + "/" + wDate + "/"
        let requestCity = "https://www.metaweather.com/api/location/search/?query=" + city
        guard let url = URL(string: requestCity) else {return ""}
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
                    var cityNumber = "400"
                    WeatherCity = try decoder.decode([CityForWeather].self, from: data)
                    if WeatherCity.count > 0 {
                        cityNumber = String(WeatherCity[0].woeid)
                        print("found???????????", "https://www.metaweather.com/api/location/" + cityNumber + "/" + wDate + "/")
                    } else {
                        cityNumber = "2357024"
                    }
                    returnValue = "https://www.metaweather.com/api/location/" + cityNumber + "/" + wDate + "/"
                } catch let error {
                    print("Parsing Failed \(error.localizedDescription)")
                }
            }
        }
        dataTask.resume()
        return returnValue
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
        cell.occurrenceDate.text = item.occurrenceDate
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
