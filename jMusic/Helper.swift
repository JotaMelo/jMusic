//
//  Helper.swift
//  jMusic
//
//  Created by Jota Melo on 31/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import UIKit
import UserNotifications

class Helper {
    static var testMode = false
    
    static func userDefaults() -> UserDefaults {
        return UserDefaults.standard
    }
    
    static func defaultsObject(forKey key: String) -> Any? {
        return self.userDefaults().object(forKey: key)
    }
    
    static func set(_ value: Any?, forKey key: String) {
        let userDefaults = self.userDefaults()
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }
    
    static func removeDefaultsObject(forKey key: String) {
        let userDefaults = self.userDefaults()
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
    static func showNotificationWith(body: String, alert: Bool) {
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = alert ? UNNotificationSound.default() : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
