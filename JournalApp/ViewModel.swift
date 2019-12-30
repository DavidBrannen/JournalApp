//
//  ViewModel.swift
//  JournalApp
//
//  Created by David Brannen on 12/30/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import CoreData

class ViewModel {
    var arrayOfCityDayWeathers: [CityDayWeather] = []
    
    func fetchWeather(items: [NSManagedObject]) -> [NSManagedObject] {
        for index in items.indices {
            //https://www.metaweather.com/api/location/search/?query=atlanta
            let locationNumber = "2357024"
            var wDate = items[index].value(forKeyPath: "date") as! String
            wDate = convertDateFormater(wDate)
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
                        self.arrayOfCityDayWeathers = try decoder.decode([CityDayWeather].self, from: data)
                        if let item = items[index] as? Item {
                            if self.arrayOfCityDayWeathers.count > 0 {
                                item.weather_state_name = self.arrayOfCityDayWeathers[0].weather_state_name
                            }
                        }
                    } catch let error {
                        print("Parsing Failed \(error.localizedDescription)")
                    }
                }
            }
            dataTask.resume()
        }
        return items
    }
    func convertStringToDate(_ date: String) -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM/dd/yy"
        let dateDate = dateFormatterGet.date(from: date)!
        return dateDate
    }
    func convertDateFormater(_ date: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM/dd/yy"
        let dateDate = dateFormatterGet.date(from: date)!
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy/MM/dd"
        return dateformat.string(from: dateDate)
        
    }
}
