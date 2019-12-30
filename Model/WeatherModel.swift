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
