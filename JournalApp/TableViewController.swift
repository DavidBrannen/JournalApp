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
        self.tableView.estimatedRowHeight = 44
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
    func fetchWeather() {
        let viewModel: ViewModel = ViewModel()
        items = viewModel.fetchWeather(items: items)
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
}
