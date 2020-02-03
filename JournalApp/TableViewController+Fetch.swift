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
 
 2. weather updated date if needed
 
 while adding/updating save udate and weather states
 */

extension TableViewController {
    
    // MARK: - Data Fetch
    func fetchData() {
        let sort = NSSortDescriptor(key: #keyPath(Item.timestamp), ascending: true)
        items = persistenceManager.fetch(Item.self, sort: sort)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        ifNeededUpdateWeather()
    }
    
    // MARK: - Update Weather
//State pattern - the weather forcast object behavior depends on if it is the most current forcast unitl the date has past, and it must change at run-time depending on the new forcast.
    func ifNeededUpdateWeather() {
        let formatteryyyy = DateFormatter()
        formatteryyyy.dateFormat = "yyyy/MM/dd"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        
        for index in items.indices {
            //check odate to udate and skip if it has been update already today.
            //skip this loop if "oDate \(occurrenceDate) is smaller than uDate \(weatherUpdateDate) or Both dates are same - SKIPPED"
            let occurrenceDate = formatteryyyy.date(from: items[index].value(forKey: "occurrenceDate") as! String)
            let testDateData = items[index].value(forKey: "weatherUpdateDate")
            var weatherUpdateDate =  items[index].value(forKey: "timestamp") as! Date
            if testDateData != nil {
                weatherUpdateDate = formatter.date(from: items[index].value(forKey: "weatherUpdateDate") as! String)!
            }
            if occurrenceDate?.compare(weatherUpdateDate) == .orderedSame  //dates equal
                || occurrenceDate?.compare(weatherUpdateDate) == .orderedAscending //oDate is smaller then the udate
                || formatter.date (from: getCurrentDate())?.compare(weatherUpdateDate) == .orderedSame  //already updated
            {continue}

            fetchWeatherFromRemote(index: index)
        }
    }
    func fetchWeatherFromRemote(index: NSInteger) {
        // 1. make a group
        let group = DispatchGroup()
        //"https://www.metaweather.com/api/location/\(cityNum)/\(oDate)/"
        let oDate = (self.items[index].value(forKey: "occurrenceDate") as! String)
        let cityNum = self.items[index].value(forKey: "cityNumber") as! String
        let weatherURL = "https://www.metaweather.com/api/location/\(cityNum)/\(oDate)/"
        self.items[index].setValue(weatherURL, forKey: "urlWeatherCityNumberDate")
        guard let request = self.items[index].value(forKey: "urlWeatherCityNumberDate") as? String else {
            return
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
//                    let mid = (cityDayWeathers.count / 2) as NSInteger
                    let state = cityDayWeathers[0].weather_state_name
                    let state_abbr = cityDayWeathers[0].weather_state_abbr
                    self.items[index].setValue(state, forKey: "weather_state_name")
                    self.items[index].setValue(state_abbr, forKey: "weather_state_abbr")
                    self.items[index].setValue(self.getCurrentDate() as String, forKey: "weatherUpdateDate")
                    self.persistenceManager.save()
                    print("weather forcast may have changed for \(oDate)")
                }
            } catch let error {
                print("Parsing Failed \(error.localizedDescription)")
            }
            // 3. leave the group for each task, when task is done
            group.leave()
        }
        dataTask.resume()

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
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        let date = Date()
        return formatter.string(from: date)
    }
    /// call to update the table, when done.
    func reloadUI() {
        DispatchQueue.main.async {
            // self.persistenceManager.save()
            self.tableView.reloadData()
        }
    }
    
    
}
