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
    let persistenceManager: PersistenceManager
    init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        persistenceManager = PersistenceManager.shared
        super.init(coder: aDecoder)
    }

    
    let cellId = "Cell"
    var items: [NSManagedObject] = []
    var arrayOfCityDayWeathers: [CityDayWeather] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Entries"
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
        fetchWeather()
    }
    
    /// loads any offline data & reloads the UI
    func fetchData() {
        items = persistenceManager.fetch(Item.self)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    /// downloads data from your remote
    //https://www.metaweather.com/api/location/2357024/2019/12/13/
    func fetchWeather() {
        for index in items.indices {
            //https://www.metaweather.com/api/location/search/?query=atlanta //arrayOfItems[index].cityText
            let locationNumber = "2357024"
            var wDate = items[index].value(forKeyPath: "date") as! String
            wDate = convertDateFormater(wDate)
            var request = "https://www.metaweather.com/api/location/" + locationNumber + "/"
            request = request  + wDate + "/"
            guard let url = URL(string: request) else {return}
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
                        if let item = self.items[index] as? Item {
                            item.weather_state_name = self.arrayOfCityDayWeathers[0].weather_state_name
                        }
                    } catch let error {
                        print("Parsing Failed \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
            dataTask.resume()
        }
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

extension TableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> JournalCell {
        let item = items[indexPath.row] as! Item
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! JournalCell
        var timeStamp: String = ""
        let date = item.date
        let time = item.time
        if let date = date, let time = time {
            timeStamp = "Added on \(date) at \(time)"
        }
        cell.entryLabel.text   = item.entry
        cell.timeLabel.text    = timeStamp
        cell.weatherState.text = item.weather_state_name
        
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
    ///use in cellFor Row
    //                    if let i = item as? Item {
    //                        print(i.timestamp)
    //                    }

    ///use at the end of fetchData() to replace/update core data - one time only
    //    func updateItems() {
    //        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
    //            return
    //        }
    //        let managedContext = appDelegate.backgroundContext
    //        guard NSEntityDescription.entity(forEntityName: "Item", in: managedContext) != nil else {
    //            return }
    //
    //        for index in items.indices {
    //            //            if items[index].value(forKeyPath: "timestamp") == "2019-12-19 00:10:59 +0000" {
    //            let newDate = convertStringToDate(items[index].value(forKeyPath: "date") as! String)
    //            items[index].setValue(newDate, forKey: "timestamp")
    //
    //            do {
    //                try managedContext.save()
    //            } catch let error as NSError {
    //                print("Could not save1. \(error), \(error.userInfo)")
    //            }
    //            appDelegate.saveCoreDataChanges()
    //        }
    //
    //    }
}
