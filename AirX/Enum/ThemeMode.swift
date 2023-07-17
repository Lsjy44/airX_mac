//
//  ThemeMode.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation

/// 主题模式
enum ThemeMode: String, CaseIterable {
   case light = "Light Mode"
   case dark = "Dark Mode"
   
   var theme: Theme {
       switch self {
       case .light:
           return LightMode()
       case .dark:
           return DarkMode()
       }
   }
}
