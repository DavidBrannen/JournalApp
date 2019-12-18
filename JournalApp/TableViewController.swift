//
//  TableViewController.swift
//  JournalApp
//
//  Created by David Brannen on 12/5/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import UIKit
import CoreData

struct EntryStrut {
    var entryText: String?
    var dateOfWeather: String?
    var timeStamp: String
    var cityText: String?
    var weatherStateText: String
}
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
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var items: [NSManagedObject] = []
    var arrayOfItems: [EntryStrut] = []
    var arrayOfCityDayWeathers: [CityDayWeather] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Entries"
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        arrayOfItems = []
        fetchData()
        updateWeatherState()
    }
    
    func fetchData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
        
        do {
            items = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not Fetch Data. \(error), \(error.userInfo)")
        }
        displayArray()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func displayArray() {
        arrayOfItems = []
        for item in items {
            let dateOfWeather = convertDateFormater((item.value(forKey: "date") as? String)!)
            var timeStamp: String = ""
            let date = item.value(forKeyPath: "date") as? String
            let time = item.value(forKeyPath: "time") as? String
            if let date = date, let time = time {
                timeStamp = "Added on \(date) at \(time)"
            }
            let cityText = "Atlatna"
            arrayOfItems.append(EntryStrut(entryText: item.value(forKey: "entry") as? String, dateOfWeather: dateOfWeather, timeStamp: timeStamp, cityText: cityText, weatherStateText: ""))
        }
        arrayOfItems.sort {$0.timeStamp < $1.timeStamp}
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
        let item = arrayOfItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! JournalCell
        
        cell.entryLabel.text   = item.entryText
        cell.timeLabel.text    = item.timeStamp
        cell.weatherState.text = item.weatherStateText

        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfItems.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            
            let item = self.items[indexPath.row]
            self.context.delete(item)
            self.items.remove(at: indexPath.row)
            (UIApplication.shared.delegate as! AppDelegate).saveBackground()
            self.arrayOfItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        return swipeActions
    }
    
    //https://www.metaweather.com/api/location/2357024/2019/12/13/
    
    func updateWeatherState() {
        for index in arrayOfItems.indices {
            //https://www.metaweather.com/api/location/search/?query=atlanta //arrayOfItems[index].cityText
            let locationNumber = "2357024"
            let wDate = arrayOfItems[index].dateOfWeather
            var request = "https://www.metaweather.com/api/location/" + locationNumber
            request = request + "/" + wDate! + "/"
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
                        self.arrayOfCityDayWeathers = try decoder.decode([CityDayWeather].self, from: data)
                        self.arrayOfItems[index].weatherStateText = self.arrayOfCityDayWeathers[0].weather_state_name
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    } catch let error  {
                        print("Parsing Failed \(error.localizedDescription)")
                    }
                }
            }
            task.resume()

        }
    }
}
