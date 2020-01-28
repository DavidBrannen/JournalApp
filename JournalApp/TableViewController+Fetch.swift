//
//  TableViewController+Fetch.swift
//  JournalApp
//
//  Created by David on 1/8/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import UIKit

/*
 1. load offline data /* then reload UI */

 3. updateCityNumber
 4. fetch_weather_from_remote
 5. Save Data // update_data
 6. Reload UI // and_reload_ui
 
 // Dependencies (A->B, where A depends on B finishing first)
 
 6 -> 4 (many actions)
 4 -> 3
 3 -> 1
 */

extension TableViewController {
    
    // MARK: - Data Fetch
    func fetchData() {
        let sort = NSSortDescriptor(key: #keyPath(Item.timestamp), ascending: true)
        items = persistenceManager.fetch(Item.self, sort: sort)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func fetchCityNumber() {
        let group = DispatchGroup()
        for index in items.indices {
            //check odate
            if items[index].value(forKey: "occurrenceDate") == nil || items[index].value(forKey: "occurrenceDate") as? String == "" {
                self.items[index].setValue(items[index].value(forKey: "date"), forKey: "occurrenceDate")
            }
            //skip this loop if city number is there / unless there is a change
            if items[index].value(forKey: "cityNumber") != nil {continue}
            if let wCity = (items[index].value(forKeyPath: "city") as? String)?.lowercased(){
                var cityNum = "2357024" //default
                let requestCity = "https://www.metaweather.com/api/location/search/?query=\(wCity)"
                guard let url = URL(string: requestCity) else {return}
                
                group.enter()
                let dataTask = session.dataTask(with: url) {
                    (data, response, error) in
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
                        } catch let error {
                            print("Parsing Failed \(error.localizedDescription)")
                        }
                    }
                    group.leave()
                }
                dataTask.resume()
                group.notify(queue: .main) {
                    self.fetchWeatherFromRemote()
                }
            }
        }
    }
    /// for every item, download an additional item
    /// DispatchGroup - since the last task is dependent on multiple fetch tasks, we'll group the fetch tasks together
    ////                          - allows us to treat many tasks as a single unit
    func fetchWeatherFromRemote() {
        // 1. make a group
        let group = DispatchGroup()
        for index in items.indices {
            // we already have the weather state name, don't continue.
            guard let item = items[index] as? Item, item.weather_state_name == nil else { continue }
            if item.value(forKey: "weather_state_name") != nil {
                continue
            }
            if item.value(forKey: "date") == nil { // bad data
                continue
            }
//"https://www.metaweather.com/api/location/\(cityNum)/\(oDate)/"
            var oDate = (self.items[index].value(forKey: "occurrenceDate") as! String)
            oDate = self.convertDateFormater(oDate, inFormat: "MM/dd/yy")
            let cityNum = self.items[index].value(forKey: "cityNumber") as! String
            let weatherURL = "https://www.metaweather.com/api/location/\(cityNum)/\(oDate)/"
            self.items[index].setValue(weatherURL, forKey: "urlWeatherCityNumberDate")
            guard let request = item.value(forKey: "urlWeatherCityNumberDate") as? String else {
                continue
            }
            // 2. enter the group for each task
            group.enter()
            guard let url = URL(string: request) else { return }
            let dataTask = session.dataTask(with: url) { (data, response, error) in
                if error != nil { print(error!); return}
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    print(response!)
                    return
                }
                guard let data = data else { return }
                let decoder = JSONDecoder()
                do {
                    /// once data is received & serialized, place within structure
                    var cityDayWeathers: Array<CityDayWeather>
                    cityDayWeathers = try decoder.decode([CityDayWeather].self, from: data)
                    if cityDayWeathers.isEmpty == false {
                        let mid = (cityDayWeathers.count / 2) as NSInteger
                        let state = cityDayWeathers[mid].weather_state_name
                        let state_abbr = cityDayWeathers[mid].weather_state_abbr
                        self.items[index].setValue(state, forKey: "weather_state_name")
                        self.items[index].setValue(state_abbr, forKey: "weather_state_abbr")
                    }
                } catch let error {
                    print("Parsing Failed \(error.localizedDescription)")
                }
                
                // 3. leave the group for each task, when task is done
                group.leave()
            }
            dataTask.resume()
        }
        
        // 4. declare what action the group will take when all tasks are done
        group.notify(queue: .main) {
            self.reloadUI()
        }
    }
    func convertDateFormater(_ date: String, inFormat: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = inFormat
        let dateDate = dateFormatterGet.date(from: date) ?? Date()
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy/MM/dd"
        return dateformat.string(from: dateDate)
    }
    
    /// call to update the table, when done.
    func reloadUI() {
        DispatchQueue.main.async {
            // self.persistenceManager.save()
            self.tableView.reloadData()
        }
    }
    
    
}
