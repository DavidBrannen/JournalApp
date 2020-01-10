//
//  AddItemViewController.swift
//  JournalApp
//
//  Created by David Brannen on 12/6/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import UIKit
import CoreData

class AddItemViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var occurrenceDate: UITextField!
    @IBOutlet weak var metroplex: UITextField!
    @IBOutlet weak var itemEntryTextView: UITextView!
    let emtyEntryAlertTitle = "Please Type Something"
    let emtyEntryAlertMessage = "Your entry was left blank."
    let emtyEntryAlertActionTitle = "Okay"
    let homeMetroplex = "atlanta"
    private var datePicker = UIDatePicker()

    let persistenceManager: PersistenceManager
    init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        persistenceManager = PersistenceManager.shared
        super.init(coder: aDecoder)
    }
  // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(self.dateChanged(datePicker:)), for: .valueChanged)
        occurrenceDate.inputView = datePicker
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gesterRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        itemEntryTextView?.delegate = self
        addEntrySetup()
    }
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        occurrenceDate.text = dateFormatter.string(from: datePicker.date)
        
        view.endEditing(true)
    }
    @objc func viewTapped(gesterRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    func addEntrySetup() {
        let sort = NSSortDescriptor(key: #keyPath(Item.timestamp), ascending: false)
        let results: Array = persistenceManager.fetch(Item.self, sort: sort);
        if let first = results.first, let city = first.city {
            metroplex.text = city
        }
        else {
            metroplex.text = homeMetroplex
        }
    }
  // MARK: - Buttons
    @IBAction func saveContactButton(_ sender: Any) {
        var items: [NSManagedObject] = []
        
        guard let enteredText = itemEntryTextView?.text else {
            return
        }
        
        if enteredText.isEmpty || itemEntryTextView?.text == "Type anything..."{
            
            let alert = UIAlertController(title: emtyEntryAlertTitle, message: emtyEntryAlertMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: emtyEntryAlertTitle, style: .default) { action in })
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            let currentDate = formatter.string(from: date)
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let currentTime = timeFormatter.string(from: date)
            let oDate: String
            if occurrenceDate.text == "" || occurrenceDate.text == nil {
                oDate = currentDate } else {
                oDate = occurrenceDate.text ?? ""
            }
            let city = metroplex.text
            guard let entryText = itemEntryTextView?.text else {
                return
            }
            let item = Item(context: persistenceManager.context)
            item.setValue(city, forKey: "city")
            item.setValue(oDate, forKey: "occurrenceDate")
            item.setValue(currentDate, forKey: "date")
            item.setValue(currentTime, forKey: "time")
            item.setValue(entryText, forKey: "entry")
            item.setValue(Date(), forKey: "timestamp")

            items.append(item)
            persistenceManager.save()
        }        
        dismiss(animated: true, completion: nil)
    }
    @IBAction func cancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
      // MARK: - textView
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = ""
        textView.textColor = UIColor.black
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}


