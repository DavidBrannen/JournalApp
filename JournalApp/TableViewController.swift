//
//  TableViewController.swift
//  JournalApp
//
//  Created by David Brannen on 12/5/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import UIKit
import CoreData

struct Weather : Codable {
    let consolidated_weather : [CityDayWeather]
}
struct CityDayWeather : Codable {
    let id                  :  Int
    let weather_state_name  :  String
    let weather_state_abbr  :  String
    let wind_direction_compass:String
    let created             :  String
    let applicable_date     :  String
    let min_temp            :  Float
    let max_temp            :  Float
    let the_temp            :  Float
    let wind_speed          :  Float
    let wind_direction      :  Float
    let air_pressure        :  Float
    let humidity            :  Int
    let visibility          :  Float?
    let predictability      :  Int
}

class TableViewController: UITableViewController {
    let cellId = "Cell"
    let context = (UIApplication.shared.delegate as! AppDelegate).backgroundContext
    var items: [NSManagedObject] = []
    var weatherArray = [[String:String]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Entries"
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
        //        updateWeatherState() // off main queue
    }
    
    func fetchData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.backgroundContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
        
        do {
            items = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not Fetch Data. \(error), \(error.userInfo)")
        }
//        updateItems()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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

extension TableViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> JournalCell {
        let item = items[indexPath.row]
//                    if let i = item as? Item {
//                        print(i.timestamp)
//                    }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! JournalCell
        var timeStamp: String = ""
        let date = item.value(forKeyPath: "date") as? String
        let time = item.value(forKeyPath: "time") as? String
        if let date = date, let time = time {
            timeStamp = "Added on \(date) at \(time)"
        }
        cell.entryLabel.text   = item.value(forKeyPath: "entry") as? String
        cell.timeLabel.text    = timeStamp
//        cell.weatherState.text = weatherArray[indexPath.row].value as String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            
            let item = self.items[indexPath.row]
            self.context.delete(item)
            self.items.remove(at: indexPath.row)
            (UIApplication.shared.delegate as! AppDelegate).saveCoreDataChanges()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        return swipeActions
    }
    func updateItems() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.backgroundContext
        guard NSEntityDescription.entity(forEntityName: "Item", in: managedContext) != nil else {
            return }
        
        for index in items.indices {
            //            if items[index].value(forKeyPath: "timestamp") == "2019-12-19 00:10:59 +0000" {
            let newDate = convertStringToDate(items[index].value(forKeyPath: "date") as! String)
            items[index].setValue(newDate, forKey: "timestamp")
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save1. \(error), \(error.userInfo)")
            }
            appDelegate.saveCoreDataChanges()
        }
        
    }
    func convertStringToDate(_ date: String) -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM/dd/yy"
        let dateDate = dateFormatterGet.date(from: date)!
        return dateDate
    }
    //https://www.metaweather.com/api/location/2357024/2019/12/13/
    
        func updateWeatherState() {
            var arrayOfCityDayWeathers: [CityDayWeather] = []
            weatherArray = []
            for index in items.indices {
                //https://www.metaweather.com/api/location/search/?query=atlanta //arrayOfItems[index].cityText
                let locationNumber = "2357024"
                let wDate = items[index].value(forKeyPath: "dateOfWeather") as! String
                var request = "https://www.metaweather.com/api/location/" + locationNumber + "/"
                request = request  + wDate + "/"
                guard let url = URL(string: request) else {return}
                let session = URLSession.shared
                let task = session.dataTask(with: url) { (data, response, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        print(response!)
                        return
                    }
                    if let data = data {
                        let decoder = JSONDecoder()
                        do {
                            arrayOfCityDayWeathers = try decoder.decode([CityDayWeather].self, from: data)
                            let indexText = String(index)
                            self.weatherArray.append(["index" : indexText, "weatherStateText" : "arrayOfCityDayWeathers.weather_state_name"])
//                                weatherArray[index].inser(contentsOf: arrayOfCityDayWeathers.wea) =
//                            let weatherStateText = self.arrayOfCityDayWeathers[0].weather_state_name
//                            items[index].value(forKeyPath: <#T##String#>)
//                            DispatchQueue.main.async {
//                                self.tableView.reloadData()
//                            }
                        } catch let error  {
                            print("Parsing Failed \(error.localizedDescription)")
                        }
                    }
                }
                task.resume()
    
            }
        }
}
