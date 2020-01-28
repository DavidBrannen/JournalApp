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
