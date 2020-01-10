//
//  AddItemViewController+Weather.swift
//  JournalApp
//
//  Created by MAC on 1/10/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import UIKit
import CoreData

extension AddItemViewController {
    

    func getWeather() {
        print("add weather", Item.value(forKey: "urlWeatherCityNumberDate")!)
    }
}
