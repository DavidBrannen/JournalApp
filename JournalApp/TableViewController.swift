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
    var timeStamp: String?
    var cityText: String?
}

class TableViewController: UITableViewController {
    let cellId = "Cell"
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var items: [NSManagedObject] = []
    var arrayOfItems: [EntryStrut] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Entries"
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
    }
    
    func fetchData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
        
        do {
            items = try managedContext.fetch(fetchRequest)
            displayArray()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch let error as NSError {
            print("Could not Fetch Data. \(error), \(error.userInfo)")
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
            arrayOfItems.append(EntryStrut(entryText: item.value(forKey: "entry") as? String, dateOfWeather: dateOfWeather, timeStamp: timeStamp, cityText: cityText))
        }
    }
    func convertDateFormater(_ date: String) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YY"
        let date = dateFormatter.date(from: date)
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return  dateFormatter.string(from: date!)
    }
}

extension TableViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> JournalCell {
        displayArray()
        let item = arrayOfItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! JournalCell
        
        cell.entryLabel.text = item.entryText
        cell.timeLabel.text = item.timeStamp
//        getWeatherStateAbbr(weatherDate: <#T##String#>)
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
            (UIApplication.shared.delegate as! AppDelegate).saveBackground()
            
            self.items.remove(at: indexPath.row)
            self.arrayOfItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        return swipeActions
    }
}

