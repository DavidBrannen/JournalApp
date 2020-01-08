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
    let downloadLock = NSLock()
    let persistenceManager: PersistenceManager
    let session = URLSession(configuration: .default)

    init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        persistenceManager = PersistenceManager.shared
        super.init(coder: aDecoder)
    }
    typealias VoidCompletion = () -> Void
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Entries"
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        transformData()
    }    
//}

  // MARK: - tableview data source

//extension TableViewController {
    
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
