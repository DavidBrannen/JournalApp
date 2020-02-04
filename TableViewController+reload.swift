//
//  TableViewController+reload.swift
//  JournalApp
//
//  Created by Consultant on 1/29/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import UIKit

protocol ReloadProtocol: AnyObject {
    func reload()
}

extension TableViewController: ReloadProtocol {
    
    func reload() {
        fetchData(sortItem: sortkp)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let id = segue.identifier, id == "addItem", let vc = segue.destination as? AddItemViewController {
            vc.delegate = self
        }
    }
}

