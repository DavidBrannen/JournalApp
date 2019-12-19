//
//  AddItemViewController.swift
//  JournalApp
//
//  Created by MAC on 12/6/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import UIKit
import CoreData

class AddItemViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var itemEntryTextView: UITextView!
    
    @IBAction func cancel(_ sender: UIButton) {
         dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveContact(_ sender: Any) {
        var items: [NSManagedObject] = []
        
        guard let enteredText = itemEntryTextView?.text else {
            return
        }
        
        if enteredText.isEmpty || itemEntryTextView?.text == "Type anything..."{
            
            let alert = UIAlertController(title: "Please Type Something", message: "Your entry was left blank.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default) { action in })
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/YY"
            let currentDate = formatter.string(from: date)
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let currentTime = timeFormatter.string(from: date)
            
            guard let entryText = itemEntryTextView?.text else {
                return
            }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.mainContext
            guard let entity = NSEntityDescription.entity(forEntityName: "Item", in: managedContext) else {
                return }
            let item = NSManagedObject(entity: entity, insertInto: managedContext)
            item.setValue(currentDate, forKey: "date")
            item.setValue(currentTime, forKey: "time")
            item.setValue(entryText, forKey: "entry")
            item.setValue(Date(), forKey: "timestamp")

            do {
                try managedContext.save()
                items.append(item)
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        (UIApplication.shared.delegate as! AppDelegate).saveCoreDataChanges()
        
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemEntryTextView?.delegate = self
    }
    
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


