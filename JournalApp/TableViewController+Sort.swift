//
//  TableViewController+Sort.swift
//  JournalApp
//
//  Created on 2/9/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import UIKit

typealias SortOption = kp

final class SortOptionsTable: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    let reuseID: String = "sortOptionCell"
    weak var sortDelegate: DropDownProtocol?
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        register(UITableViewCell.self, forCellReuseIdentifier: reuseID)
        delegate = self
        dataSource = self
    }
    
    // MARK: - TableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
   
        return SortOption.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.textLabel?.text = SortOption.allCases[indexPath.row].rawValue
        return cell
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = SortOption.allCases[indexPath.row]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sortDelegate?.dropDownPressed(option: option)
        }
    }
}

extension TableViewController {
    @objc func toggleSortOptionsMenu() {
        sortButton.isEnabled = false
        animateToggleSortOptionsMenu(tagValue: sortButton.tag) { newTagVal in
            self.sortButton.tag = newTagVal
            self.sortButton.isEnabled = true
        }
    }
    
    func animateToggleSortOptionsMenu(tagValue: Int,
                                      _ completion: ((Int) -> Void)? = nil) {
        // determine size to grow/shrink to
        let endFrame: CGRect
        let endTag: Int
        switch tagValue {
            case 0:
                endFrame = CGRect(x: 0, y: 0,
                                  width: 200.0,
                                  height: Double(SortOption.allCases.count) * 44.0)
                endTag = 1
            default:
                endFrame = .zero
                endTag = 0
        }
        
        // perform the animation
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseInOut,
                       animations: {
                        self.sortOptionsTable.frame = endFrame
        }) { finished in
            if finished { completion?(endTag) }
        }
    }
}

extension TableViewController: DropDownProtocol {
    func dropDownPressed(option: SortOption) {
        sortkp = option
        fetchData(sortItem: sortkp)
        toggleSortOptionsMenu()
        self.reloadUI()
    }
}
