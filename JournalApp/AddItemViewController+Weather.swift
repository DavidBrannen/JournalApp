//
//  AddItemViewController+Weather.swift
//  JournalApp
//
//  Created by MAC on 1/10/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import UIKit
/*
 1. get new data - start filling core data record
 2. updateCityNumberNew
 3. fetchWeatherFromRemoteNew
 4. Save Data // update_data
 5. Reload UI // and_reload_ui
 
 // Dependencies (A->B, where A depends on B finishing first)
 
 5 -> 3 (many actions)
 3 -> 2
 3 -> 1
 */
extension AddItemViewController {
    
    
    func newData() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        let currentDate = formatter.string(from: date)
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let currentTime = timeFormatter.string(from: date)
        let oDate: String
        if occurrenceDate.text == "" || occurrenceDate.text == nil {
            oDate = currentDate } else {
            oDate = occurrenceDate.text ?? ""
        }
        self.urlODate = oDate
        let city = metroplex.text
        guard let entryText = itemEntryTextView?.text else {
            return
        }
        let item = Item(context: persistenceManager.context)
        item.setValue(city, forKey: "city")
        item.setValue(oDate, forKey: "occurrenceDate")
        item.setValue(currentDate, forKey: "date")
        item.setValue(currentTime, forKey: "time")
        item.setValue(entryText, forKey: "entry")
        item.setValue(Date(), forKey: "timestamp")
        DispatchQueue.main.async {
            self.persistenceManager.save()
        }
    }
    
    func fetchCityNumberNew() {
        let groupAdd = DispatchGroup()
        if let wCity = metroplex.text?.lowercased(){
            let requestCity = "https://www.metaweather.com/api/location/search/?query=\(wCity)"
            guard let url = URL(string: requestCity) else {return}
            
            groupAdd.enter()
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
                        self.urlCityNum = "2357024" //default
                        /// once data is received & serialized, return with locationNumber = cityNumber
                        WeatherCity = try decoder.decode([CityForWeather].self, from: data)
                        if WeatherCity.count > 0 {
                            self.urlCityNum = String(WeatherCity[0].woeid)
                        }
                        let item = Item(context: self.persistenceManager.context)
                        item.setValue(self.urlCityNum, forKey: "cityNumber")
                    } catch let error {
                        print("error in fetchCityNumberNew \(error)")
                    }
                }
                groupAdd.leave()
            }
            dataTask.resume()
            groupAdd.notify(queue: .main) {
                self.fetchWeatherFromRemoteNew()
            }
        }
    }
    func fetchWeatherFromRemoteNew() {
        // 1. make a group
        let group = DispatchGroup()
        //"https://www.metaweather.com/api/location/\(cityNum)/\(oDate)/"
        let oDate = self.convertDateFormater(self.urlODate, inFormat: "MM/dd/yy")
        let weatherURL = "https://www.metaweather.com/api/location/\(urlCityNum)/\(oDate)/"
        let item = Item(context: persistenceManager.context)
        item.setValue(weatherURL, forKey: "urlWeatherCityNumberDate")
        let request = weatherURL
        print(request)
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
                    let item = Item(context: self.persistenceManager.context)
                    item.setValue(state, forKey: "weather_state_name")
                }
            } catch let error {
                Swift.print("Parsing Failed \(error.localizedDescription)")
            }
            
            // 3. leave the group for each task, when task is done
            group.leave()
        }
        dataTask.resume()
        
        
        // 4. declare what action the group will take when all tasks are done
        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.persistenceManager.save()
            }
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
}
