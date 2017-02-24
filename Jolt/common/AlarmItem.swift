//
//  AlarmItem.swift
//  Jolt
//
//  Created by user on 12/24/16.
//  Copyright © 2016 user. All rights reserved.
//

import UIKit

let APP_UUID: String = "Jolt-Alarm-UUID"

struct AlarmItem {
    var actived: Bool
    var deadline: Date
    var repeatMode: String
    var snoozetime: Int
    var ringtones: String
    var UUID: String
    var createDate: Date
    
    init(actived: Bool, deadline: Date, repeatMode: String, snoozetime: Int, ringtones: String, UUID: String, createDate: Date) {
        self.actived = actived
        self.deadline = deadline
        self.repeatMode = repeatMode
        self.snoozetime = snoozetime
        self.ringtones = ringtones
        self.UUID = UUID
        self.createDate = createDate
    }
    
    var isOverdue: Bool {
        return (Date().compare(self.deadline) == ComparisonResult.orderedDescending)
    }
}



class AlarmList: NSObject {
    
    var selectedAlarm: Int = 0
    var status: Bool = false
    var snoozeTime: Date = Date()
    var snoozestatus: Bool = false
    
    //var instance: AlarmList? = nil
    
    class var sharedInstance : AlarmList {
        struct Static {
            static let instance: AlarmList = AlarmList()
        }
        return Static.instance
    }
    func allItems() -> [AlarmItem]! {
        let alarmItems: [AlarmItem] = getAllItems()
        let sorted_alarmItems = alarmItems.sorted(by: {$0.createDate.compare($1.createDate) == .orderedAscending})
        return sorted_alarmItems
    }
    func getAllItems() -> [AlarmItem]! {
        let data = UserDefaults.standard.data(forKey: "Jolt-Alarmlist")
        if data == nil {
            return [AlarmItem]()
        }
        var items: NSMutableDictionary = [:]
        items = NSKeyedUnarchiver.unarchiveObject(with: data!) as! NSMutableDictionary
        //let items: Dictionary? = NSKeyedUnarchiver.unarchiveObject(with: data!) as! Dictionary
        
        let itemArray = Array(items.allValues)
        
        return itemArray.map({
            let item = $0 as! NSDictionary
            return AlarmItem(actived: item["actived"] as! Bool, deadline: item["deadline"] as! Date, repeatMode: item["repeatMode"] as! String, snoozetime: item["snoozetime"] as! Int, ringtones: item["ringtones"] as! String, UUID: item["UUID"] as! String, createDate: item["createDate"] as! Date)
        })
    }
    
    func getPlayStatus() -> Bool {
        return status
    }
    func setPlayStatus(val: Bool) {
        status = val
    }
    
    func getSnoozeTime() -> Date {
        let data = UserDefaults.standard.data(forKey: "Jolt-SnoozeDate")
        if data == nil {
            snoozeTime = Date()
        } else {
            snoozeTime = NSKeyedUnarchiver.unarchiveObject(with: data!) as! Date
        }
        return snoozeTime
    }
    func setSnoozeTime(val: Date) {
        snoozeTime = val
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: val)
        UserDefaults.standard.set(data, forKey: "Jolt-SnoozeDate")
    }
    func getSnoozeStatus() -> Bool {
        if (UserDefaults.standard.bool(forKey: "Jolt-SnoozeStatus")) {
            snoozestatus = true
        } else {
            snoozestatus = false
        }
        return snoozestatus
    }
    func setSnoozeStatus(val: Bool) {
        snoozestatus = val
        UserDefaults.standard.set(snoozestatus, forKey: "Jolt-SnoozeStatus")
    }
    
    func addAlarm(alarmItem: AlarmItem) {
        var alarmItems: [AlarmItem] = allItems()
        alarmItems.append(alarmItem)
        saveAlarm(alarmItems: alarmItems)
    }
    func updateItem(item :AlarmItem, index:Int) {
        var alarmItems: [AlarmItem] = allItems()
        
        alarmItems[index] = item
        saveAlarm(alarmItems: alarmItems)
    }
    func removeAlarm(index: Int) {
        var alarmItems: [AlarmItem] = allItems()
        alarmItems.remove(at: index)
        saveAlarm(alarmItems: alarmItems)
    }
    func saveAlarm(alarmItems: [AlarmItem]) {
        let todoDictionary: NSMutableDictionary = [:]
        var index: Int = 0
        for item in alarmItems {
            todoDictionary[index] = ["actived": item.actived, "deadline": item.deadline, "repeatMode": item.repeatMode, "snoozetime": item.snoozetime, "ringtones": item.ringtones, "UUID": item.UUID, "createDate": item.createDate]
            index += 1
        }
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: todoDictionary)
        UserDefaults.standard.set(data, forKey: "Jolt-Alarmlist")
        //UserDefaults.standard.synchronize()
    }
    
    func getEarliestAlarmDate() -> Date {
        let alarmItems: [AlarmItem] = allItems()
        var index: Int = 0
        var date:Date? = nil
        
        for item in alarmItems {
            if (item.deadline < Date() && item.repeatMode == "") {
                AlarmList.sharedInstance.removeAlarm(index: index)
                index += 1
                continue
            }
            index += 1
            if item.actived {
                var scheduleDate: Date = item.deadline
                let now = NSDate()
                
                if (scheduleDate < now as Date) {
                    let gregorian = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
                    var components1 = gregorian.components([.year, .month, .day, .hour, .minute, .second], from: now as Date)
                    let components2 = gregorian.components([.year, .month, .day, .hour, .minute, .second], from: scheduleDate as Date)
                    
                    // Change the time to 9:30:00 in your locale
                    components1.hour = components2.hour
                    components1.minute = components2.minute
                    components1.second = components2.second
                    
                    scheduleDate = gregorian.date(from: components1)!
                }
                let datesForNotification = correctDate(scheduleDate, onWeekdaysForNotify:item.repeatMode)
                
                for d in datesForNotification
                {
                    if( d > Date()) {
                        if (date == nil || d < date! ) {
                            date = d
                        }
                    }
                }
            }
        }
        
        if (AlarmList.sharedInstance.getSnoozeStatus() == true) {
            if (AlarmList.sharedInstance.getSnoozeTime() < Date()) {
                AlarmList.sharedInstance.setSnoozeStatus(val: false)
            } else {
                if (date == nil || (date != nil && date! > AlarmList.sharedInstance.getSnoozeTime())) {
                    date = AlarmList.sharedInstance.getSnoozeTime()
                }
            }
        }
        
        return date!
    }
    func reScheduleAlarm(snoozeTime: Int) {
        UIApplication.shared.cancelAllLocalNotifications()
//        let scheduledNotifications: [UILocalNotification]? = UIApplication.shared.scheduledLocalNotifications
//        guard scheduledNotifications != nil else {return} // Nothing to remove, so return
//        
//        for notification in scheduledNotifications! { // loop through notifications...
//            if (notification.userInfo!["UUID"] as! String == APP_UUID) {
//                UIApplication.shared.cancelLocalNotification(notification)
//            }
//        }
        
        let alarmItems: [AlarmItem] = allItems()
        var index: Int = 0
        
        for item in alarmItems {
            if (item.deadline < Date() && item.repeatMode == "") {
                AlarmList.sharedInstance.removeAlarm(index: index)
                index += 1
                continue
            }
            index += 1
            if item.actived {
                var scheduleDate: Date = item.deadline
                let now = NSDate()
                
                if (scheduleDate < now as Date) {
                    let gregorian = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
                    var components1 = gregorian.components([.year, .month, .day, .hour, .minute, .second], from: now as Date)
                    let components2 = gregorian.components([.year, .month, .day, .hour, .minute, .second], from: scheduleDate as Date)
                    
                    // Change the time to 9:30:00 in your locale
                    components1.hour = components2.hour
                    components1.minute = components2.minute
                    components1.second = components2.second
                    
                    scheduleDate = gregorian.date(from: components1)!
                }
                setNotificationWithDate(scheduleDate as Date, onWeekdaysForNotify: item.repeatMode, snooze: item.snoozetime)
            }
        }
        
        if(snoozeTime > 0) {
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .minute, value: snoozeTime, to: Date())
            
            let AlarmNotification = UILocalNotification()
            AlarmNotification.alertBody = "Alarm Notification"
            AlarmNotification.alertAction = "Open"
            //notification.fireDate = alarmItem?.deadline
            AlarmNotification.soundName = UILocalNotificationDefaultSoundName//self.currentAlarmSongUrl()
            AlarmNotification.userInfo = ["title": "Jolt Alarm", "UUID": APP_UUID, "snooze" : String(snoozeTime)]
            AlarmNotification.applicationIconBadgeNumber = 1
            AlarmNotification.timeZone = NSTimeZone.default
            AlarmNotification.fireDate = date
            UIApplication.shared.scheduleLocalNotification(AlarmNotification)
        }
        // already set snoozeAlarm
        if (self.snoozestatus == true && self.snoozeTime > Date()) {
            let AlarmNotification = UILocalNotification()
            AlarmNotification.alertBody = "Alarm Notification"
            AlarmNotification.alertAction = "Open"
            //notification.fireDate = alarmItem?.deadline
            AlarmNotification.soundName = UILocalNotificationDefaultSoundName//self.currentAlarmSongUrl()
            AlarmNotification.userInfo = ["title": "Jolt Alarm", "UUID": APP_UUID, "snooze" : String(snoozeTime)]
            AlarmNotification.applicationIconBadgeNumber = 1
            AlarmNotification.timeZone = NSTimeZone.default
            AlarmNotification.fireDate = self.snoozeTime
            UIApplication.shared.scheduleLocalNotification(AlarmNotification)
        }
    }
    
    func setNotificationWithDate(_ date: Date, onWeekdaysForNotify weekdays:String, snooze: Int) {
        
        let datesForNotification = correctDate(date, onWeekdaysForNotify:weekdays)
        
        for d in datesForNotification
        {
            if( d > Date()) {
                let AlarmNotification = UILocalNotification()
                AlarmNotification.alertBody = "Alarm Notification"
                AlarmNotification.alertAction = "Open"
                //notification.fireDate = alarmItem?.deadline
                AlarmNotification.soundName = UILocalNotificationDefaultSoundName//self.currentAlarmSongUrl()
                AlarmNotification.userInfo = ["title": "Jolt Alarm", "UUID": APP_UUID, "snooze" : String(snooze), "fire" : String(snooze)]
                AlarmNotification.applicationIconBadgeNumber = 1
                AlarmNotification.timeZone = NSTimeZone.default
                AlarmNotification.fireDate = d
                UIApplication.shared.scheduleLocalNotification(AlarmNotification)
            }
        }
    }
    
    func currentAlarmSongUrl() -> String{
        if (UserDefaults.standard.string(forKey: "alarmSongUrl") != nil){
            print(UserDefaults.standard.string(forKey: "alarmSongUrl")!)
            return UserDefaults.standard.string(forKey: "alarmSongUrl")!
        }
        return UILocalNotificationDefaultSoundName
    }
    
    func updateAlarmSongUrl(strAlarmSongUrl: String){
        UserDefaults.standard.setValue(strAlarmSongUrl, forKey: "alarmSongUrl")
    }
    
    func correctDate(_ date: Date, onWeekdaysForNotify weekdays:String) -> [Date]
    {
        var correctedDate: [Date] = [Date]()
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        
        let flags: NSCalendar.Unit = [NSCalendar.Unit.weekday, NSCalendar.Unit.weekdayOrdinal, NSCalendar.Unit.day]
        let dateComponents = (calendar as NSCalendar).components(flags, from: date)
        //var nowComponents = calendar.components(flags, fromDate: now)
        let weekday:Int = dateComponents.weekday!
        
        if weekdays == ""{
            //date is eariler than current time
            if date.compare(now) == ComparisonResult.orderedAscending
            {
                correctedDate.append((calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: date, options:.matchStrictly)!)
            }
            //later
            else
            {
                correctedDate.append(date)
            }
            return correctedDate
        }
        else
        {
            var checkedArray: [Int] = []
            let short_WeekdayArray = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            
            if weekdays == "Every Day" {
                checkedArray = [1,2,3,4,5,6,7]
            } else {
                var weekdayArray = weekdays.components(separatedBy: ", ")
                var index: Int = 0
                for i in 1...short_WeekdayArray.count {
                    if short_WeekdayArray[i-1] == weekdayArray[index] {
                        index += 1
                        checkedArray.append(i)
                        if weekdayArray.count == index {
                            break
                        }
                    }
                }
            }
            
            let daysInWeek = 7
            correctedDate.removeAll(keepingCapacity: true)
            for wd in checkedArray
            {
                
                var wdDate: Date!
                //if date.compare(now) == NSComparisonResult.OrderedAscending
                if wd < weekday
                {
                    
                    wdDate =  (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: wd+daysInWeek-weekday, to: date, options:.matchStrictly)!
                }
                else if wd == weekday
                {
                    if date.compare(now) == ComparisonResult.orderedAscending
                    {
                        wdDate = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: daysInWeek, to: date, options:.matchStrictly)!
                    } 
                    else  {
                        wdDate = date
                    }
                }
                else
                {
                    wdDate =  (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: wd-weekday, to: date, options:.matchStrictly)!
                }
                
                correctedDate.append(wdDate)
            }
            return correctedDate
        }
    }
    
    func setSelectedIndex(index: Int) {
        selectedAlarm = index
    }
    
    func getSelectedAlarm() -> AlarmItem! {
        var alarmItems: [AlarmItem] = allItems()
        if selectedAlarm == -1 {
            return nil
        }
        return alarmItems[selectedAlarm]
    }
    
    func getAlarmInfo() ->AlarmJsonInfo {
        let data = UserDefaults.standard.data(forKey: "Jolt-AlarmJsonInfo")
        if data == nil {
            return AlarmJsonInfo()
        }
        let alarmInfo: AlarmJsonInfo = NSKeyedUnarchiver.unarchiveObject(with: data!) as! AlarmJsonInfo
    
        return alarmInfo
    }
    
    func setAlarmInfo(info: AlarmJsonInfo) {
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: info)
        UserDefaults.standard.set(data, forKey: "Jolt-AlarmJsonInfo")
    }
    
    func getAlarmTimeFormat() -> Bool {
        if (UserDefaults.standard.bool(forKey: "Jolt-HourFormat")) {
            return true
        } else {
            return false
        }
    }
    
    func setAlarmTimeFormat(format:Bool) {
        UserDefaults.standard.set(format, forKey: "Jolt-HourFormat")
    }
}
