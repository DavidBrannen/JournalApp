//
//  SortVeiwModel.swift
//  JournalApp
//
//  Created by Consultant on 2/6/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import UIKit

protocol DropDownProtocol: AnyObject {
    func dropDownPressed(option: SortOption)
}

class DropDownBtn: UIButton, DropDownProtocol {
    
    func dropDownPressed(option: SortOption) {
        self.setTitle(option.rawValue, for: .normal)
        dismissSortMenu()
    }
    
    var dropdownBtn = UIButton()
    var dropView = DropdownView()
    var height = NSLayoutConstraint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray
        dropView = DropdownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubviewToFront(dropView)
        dropView.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        dropView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        height = dropView.heightAnchor.constraint(equalToConstant: 0)

    }
    
    var isOpen = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOpen == false {
            isOpen = true
            NSLayoutConstraint.deactivate([self.height])
            self.height.constant = self.dropView.tableview.contentSize.height
            NSLayoutConstraint.activate([self.height])
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            }, completion: nil)
        } else {
            isOpen = false
            NSLayoutConstraint.deactivate([self.height])
            self.height.constant = 0
            NSLayoutConstraint.activate([self.height])
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.center.y -= self.dropView.frame.height / 2
                self.dropView.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func dismissSortMenu() {
        isOpen = false
        NSLayoutConstraint.deactivate([self.height])
        self.height.constant = 0
        NSLayoutConstraint.activate([self.height])
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.dropView.center.y -= self.dropView.frame.height / 2
            self.dropView.layoutIfNeeded()
        }, completion: nil)

    }
}

class DropdownView: UIView, UITableViewDelegate, UITableViewDataSource {
    var sortOptions = ["Time Stamp","Occurrence Date"]
    var tableview = UITableView ()
    var delegate : DropDownProtocol!
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableview.delegate = self
        tableview.dataSource = self
        tableview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tableview)
        tableview.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortOptions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = sortOptions[indexPath.row]
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sortOptions[indexPath.row] {
        case "Time Stamp":
            sortkp = kp.timestamp
        default:
            sortkp = kp.occurrenceDate
        }
        let option = SortOption(rawValue: sortOptions[indexPath.row])!
        self.delegate.dropDownPressed(option: option)
    }
}
