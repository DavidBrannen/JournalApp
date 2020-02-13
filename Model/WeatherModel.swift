//
//  WeatherModel.swift
//  JournalApp
//
//  Created by David Brannen on 12/24/19.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation

struct Weather : Codable {
    let consolidated_weather : [CityDayWeather]
}
struct CityDayWeather : Codable {
    let id                  :  Int
    let weather_state_name  :  String
    let weather_state_abbr  :  String
    let wind_direction_compass:String
    let created             :  String
    let applicable_date     :  String
    let min_temp            :  Float
    let max_temp            :  Float
    let the_temp            :  Float
    let wind_speed          :  Float
    let wind_direction      :  Float
    let air_pressure        :  Float
    let humidity            :  Int
    let visibility          :  Float?
    let predictability      :  Int
}

struct WeatherCity : Codable {
    let consolidated_weather : [CityForWeather]
}
struct CityForWeather : Codable {
    let title               : String
    let location_type       : String
    let woeid               : NSInteger
    let latt_long           : String
}


class Notifications {
    static let notificationWeatherReady = Notification.Name(rawValue: "weatherReady")
}

enum kp : String, CaseIterable {
    case timestamp      = "added date"
    case occurrenceDate = "occurrence"
    case alpha          = "entry"
    case reverseOrder   = "Revercse Order"
}


