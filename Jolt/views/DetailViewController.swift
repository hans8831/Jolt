//
//  DetailViewController.swift
//  Jolt
//
//  Created by user on 12/22/16.
//  Copyright © 2016 user. All rights reserved.
//

import UIKit

class ItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnCheck: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblRepeat: UILabel!
    @IBOutlet weak var lblSnoozeTime: UILabel!
    @IBOutlet weak var lblBackupRingtone: UILabel!
    @IBOutlet weak var imgCheck: UIImageView!
    @IBOutlet weak var timePicker_view: UIView!    
    @IBOutlet weak var underView: UIView!
    @IBOutlet weak var itemView: UIView!
    @IBOutlet weak var snoozeView: UIView!
    @IBOutlet weak var lbltitle_itemView: UILabel!
    @IBOutlet weak var item_tableView: UITableView!
    @IBOutlet weak var edSnoozeTime: UITextField!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var imgDelete: UIImageView!
    
    var tapGesture:UITapGestureRecognizer!
    var tapGesture_underView:UITapGestureRecognizer!
    
    var WeekdayArray = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var short_WeekdayArray = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var checkedArray = [1, 1, 1, 1, 1, 1, 1]
    var itemKind:NSInteger?
    var alarmItem: AlarmItem? = nil
    var timeformat: Bool = false
    
    ///File Manager allows us access to the device's files to which we are allowed.
    let fileManager: FileManager = FileManager()
    
    ///The directories where we will first start looking for files as well as sub directories.
    let rootSoundDirectories: [String] = ["/Library/Ringtones"] //, "/System/Library/Audio/UISounds/"]
    
    ///The directories where sound files are located.
    var directories: [NSMutableDictionary] = []
    var soundPaths: [String] = []
    
    ///The directory that we is passed to the listing view controller.
    var segueDirectory: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.timePicker_view.isHidden = true
        self.underView.isHidden = true
        self.itemView.isHidden = true
        self.snoozeView.isHidden = true
        
        for directory in rootSoundDirectories { //seed the directories we know about.
            let newDirectory: NSMutableDictionary = [
                "path" : "\(directory)",
                "files" : []
            ]
            directories.append(newDirectory)
        }
       // getDirectories()
        getSoundFiles()
        timeformat = AlarmList.sharedInstance.getAlarmTimeFormat()
        alarmItem = AlarmList.sharedInstance.getSelectedAlarm()
        
        if (alarmItem == nil) {
            alarmItem = AlarmItem(actived: true, deadline: Date(), repeatMode: "Every Day", snoozetime: 10, ringtones: soundPaths.count > 0 ? soundPaths[0] : "", UUID: APP_UUID, createDate: Date())
            self.btnDelete.isHidden = true
            self.imgDelete.isHidden = true
        }
        
        self.updateViews()
    }
    
    func updateViews() {
        if alarmItem?.actived == true {
            imgCheck.image = UIImage(named: "checked")
        } else {
            imgCheck.image = UIImage(named: "unchecked")
        }
        let dateFormatter: DateFormatter = DateFormatter()
        if (timeformat == true) {
            dateFormatter.dateFormat = "HH:mm"
            timePicker.locale = NSLocale(localeIdentifier: "en_GB") as Locale
        } else {
            dateFormatter.dateFormat = "hh:mm a"
            timePicker.locale = NSLocale(localeIdentifier: "en_US") as Locale
        }
        let selectedTime: String = dateFormatter.string(from: (alarmItem?.deadline)!)
        lblTime.text = selectedTime
        var date = alarmItem?.deadline
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var interval = date?.timeIntervalSince(Date())
        
        while (interval! < TimeInterval(-60*60*24)) {
            date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: date!, options:.matchStrictly)!
            timePicker.date = date!
            interval = timePicker.date.timeIntervalSince(Date())
        }
        
        timePicker.date = date!
        alarmItem?.deadline = date!
        
        if alarmItem?.repeatMode == "Every Day" {
            checkedArray = [1, 1, 1, 1, 1, 1, 1]
        } else {
            checkedArray = [0, 0, 0, 0, 0, 0, 0]
            var weekdayArray = (alarmItem?.repeatMode)?.components(separatedBy: ", ")
            var index: Int = 0
            for i in 1...short_WeekdayArray.count {
                if short_WeekdayArray[i-1] == weekdayArray?[index] {
                    checkedArray[i-1] = 1
                    index += 1
                    if weekdayArray?.count == index {
                        break
                    }
                }
            }
        }
        
        self.lblRepeat.text = (alarmItem?.repeatMode)!
        self.lblSnoozeTime.text = String(format:"%d", (alarmItem?.snoozetime)!)
        let tmpArray = (alarmItem?.ringtones)?.components(separatedBy: ".")
        self.lblBackupRingtone.text = "Default ringtone (" + ((tmpArray?.count)! > 0 ? (tmpArray?[0])! : "") + ")";
        
    }
    
    func getDirectories() {
        for directory in rootSoundDirectories {
            let directoryURL: URL = URL(fileURLWithPath: "\(directory)", isDirectory: true)
            do {
                var URLs: [URL]?
                URLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: FileManager.DirectoryEnumerationOptions())
                
                var urlIsaDirectory: ObjCBool = ObjCBool(false)
                for url in URLs! {
                    fileManager.fileExists(atPath: url.path, isDirectory: &urlIsaDirectory)
                    if urlIsaDirectory.boolValue {
                        let directory: String = "\(url.relativePath)"
                        let newDirectory: NSMutableDictionary = [
                            "path" : "\(directory)",
                            "files" : []
                        ]
                        directories.append(newDirectory)
                    }
                }
            } catch {
                debugPrint("\(error)")
            }
        }
    }
    
    func getSoundFiles() {
        for directory in directories {
            let directoryURL: URL = URL(fileURLWithPath: directory.value(forKey: "path") as! String, isDirectory: true)
            
            do {
                var URLs: [URL]?
                URLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: FileManager.DirectoryEnumerationOptions())
                var urlIsaDirectory: ObjCBool = ObjCBool(false)
                for url in URLs! {
                    fileManager.fileExists(atPath: url.path, isDirectory: &urlIsaDirectory)
                    if !urlIsaDirectory.boolValue {
                        soundPaths.append("\(url.lastPathComponent)")
                    }
                }
                
            } catch {
                debugPrint("\(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.menuView.isHidden = true
        timeformat = AlarmList.sharedInstance.getAlarmTimeFormat()
        let dateFormatter: DateFormatter = DateFormatter()
        if (timeformat == true) {
            dateFormatter.dateFormat = "HH:mm"
            timePicker.locale = NSLocale(localeIdentifier: "en_GB") as Locale
        } else {
            dateFormatter.dateFormat = "hh:mm a"
            timePicker.locale = NSLocale(localeIdentifier: "en_US") as Locale
        }
        lblTime.text = dateFormatter.string(from: (alarmItem?.deadline)!)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.touchOutsideMenuView()
    }
    
    func touchOutsideMenuView(){
        
        self.menuView.isHidden = true
        if tapGesture != nil {
            view.removeGestureRecognizer(tapGesture)
        }
        
    }
    
    func touchInSideUnderView(){
        if (self.snoozeView.isHidden == false) {
            self.edSnoozeTime.endEditing(true)
            if tapGesture_underView != nil {
                view.removeGestureRecognizer(tapGesture_underView)
            }
            return
        }
        
        self.underView.isHidden = true
        self.itemView.isHidden = true
        
        if tapGesture_underView != nil {
            view.removeGestureRecognizer(tapGesture_underView)
        }
        
    }
    
    func updateRepeatWeekDays() {
        var str: String = ""
        var isEveryday: Bool = true
        for i in 1...short_WeekdayArray.count {
            if checkedArray[i-1] == 1 {
                if str == "" {
                    str = short_WeekdayArray[i-1]
                } else {
                    str += ", " + short_WeekdayArray[i-1]
                }
            } else {
                isEveryday = false
            }
        }
        if isEveryday == true {
            str = "Every Day"
        }
        self.lblRepeat.text = str
        alarmItem?.repeatMode = str
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if itemKind == 1 {
            return WeekdayArray.count
        } else {
            return soundPaths.count;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemTableViewCell
        if itemKind == 1 {
            cell.btnCheck.isHidden = false
            cell.lblTitle.text = WeekdayArray[indexPath.row]
            if checkedArray[indexPath.row] == 0 {
                cell.btnCheck.setImage(UIImage(named: "unchecked1"), for: .normal)
            } else {
                cell.btnCheck.setImage(UIImage(named: "checked1"), for: .normal)
            }
        } else {
            cell.btnCheck.isHidden = true
            let path: String = soundPaths[indexPath.row]
            var tmpArray = path.components(separatedBy: "/")
            let filename: String = tmpArray.count > 0 ? tmpArray[tmpArray.count - 1] : ""
            tmpArray = filename.components(separatedBy: ".")
            cell.lblTitle.text = tmpArray.count > 0 ? tmpArray[0] : ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemTableViewCell
        
        if itemKind == 1 {
            if checkedArray[indexPath.row] == 0 {
                cell.btnCheck.setImage(UIImage(named: "checked1"), for: .normal)
                checkedArray[indexPath.row] = 1
            } else {
                cell.btnCheck.setImage(UIImage(named: "unchecked1"), for: .normal)
                checkedArray[indexPath.row] = 0
            }
            self.updateRepeatWeekDays()
            self.item_tableView.reloadData()
        } else {
            let path: String = soundPaths[indexPath.row]
            var tmpArray = path.components(separatedBy: "/")
            let filename: String = tmpArray.count > 0 ? tmpArray[tmpArray.count - 1] : ""
            tmpArray = filename.components(separatedBy: ".")
            let name: String = tmpArray.count > 0 ? tmpArray[0] : ""
            self.lblBackupRingtone.text = "Default ringtone (" + name + ")"
            alarmItem?.ringtones = filename;
            self.touchInSideUnderView()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onBack(_ sender: Any) {
        self.touchOutsideMenuView()
        //self.dismiss(animated: true, completion: nil)
        self.navigationController!.popToRootViewController(animated: true)
    }
    @IBAction func onDelete(_ sender: Any) {
        AlarmList.sharedInstance.removeAlarm(index: AlarmList.sharedInstance.selectedAlarm)
        self.navigationController!.popToRootViewController(animated: true)
    }
    @IBAction func onSave(_ sender: Any) {
        var date: Date = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var interval = timePicker.date.timeIntervalSince(Date())
        while (interval > 60 * 60 * 24) {
            date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: -1, to: (alarmItem?.deadline)!, options:.matchStrictly)!
            timePicker.date = date
            interval = timePicker.date.timeIntervalSince(Date())
        }
        if self.lblRepeat.text == "" {
            date = timePicker.date
            if (date < Date()) {
                date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: (alarmItem?.deadline)!, options:.matchStrictly)!
            }
            
            alarmItem?.deadline = date
        }
        if AlarmList.sharedInstance.getSelectedAlarm() == nil {
            AlarmList.sharedInstance.addAlarm(alarmItem: alarmItem!)
        } else {
            AlarmList.sharedInstance.updateItem(item: alarmItem!, index: AlarmList.sharedInstance.selectedAlarm)
        }
        AlarmList.sharedInstance.reScheduleAlarm(snoozeTime: 0)
        
        if alarmItem?.actived == true {
            if self.lblRepeat.text != "" {
            
                var scheduleDate: Date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 7, to: (alarmItem?.deadline)!, options:.matchStrictly)!
                
                let datesForNotification = AlarmList.sharedInstance.correctDate((alarmItem?.deadline)!, onWeekdaysForNotify:(alarmItem?.repeatMode)!)
                
                for d in datesForNotification
                {
                    if( d < scheduleDate && d > Date()) {
                        scheduleDate = d
                    }
                }
                date = scheduleDate
            }
            
            interval = date.timeIntervalSince(Date())
            var day:Int = 0
            var hour:Int = 0
            var minutes: Int = 0
            var seconds: Int = 0
            if (interval > 60 * 60) {
                hour = Int(interval / (60*60))
                if (hour > 23) {
                    day = Int(hour / 24)
                    hour = hour - day * 24
                }
                interval =  interval.truncatingRemainder(dividingBy: (60*60))
            }
            
            if (interval > 60) {
                minutes = Int(interval / 60)
                interval = interval.truncatingRemainder(dividingBy: 60)
            }
            
            seconds = Int(interval)
            
            var message: String = "Alarm will sound in "
            if (day > 0) {
                message += String(day) + " Days, "
            }
            if (hour > 0) {
                message += String(hour) + " Hours, "
            }
            if (minutes > 0) {
                message += String(minutes) + " Minutes, "
            }
            
            message += String(seconds) + " Seconds"
            
            let alertController = UIAlertController(title: "Jolt", message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                
                date = AlarmList.sharedInstance.getEarliestAlarmDate()
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = mainStoryboard.instantiateViewController(withIdentifier: "statusView") as! StatusViewController
                vc.alarmTime = date
                self.navigationController!.pushViewController(vc, animated: true)
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.navigationController!.popToRootViewController(animated: true)
            //self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func onShowMenu(_ sender: Any) {
        if (tapGesture == nil) {
            let aSelector : Selector = #selector(DetailViewController.touchOutsideMenuView)
            
            tapGesture = UITapGestureRecognizer(target: self, action: aSelector)
            tapGesture.numberOfTapsRequired = 1
        }
        view.addGestureRecognizer(tapGesture)
        
        UIView.animate(withDuration: 0.7, delay: 0.0, animations: {
            self.menuView.isHidden = false
        }, completion: nil)
    }
    
    @IBAction func onClickWebsite(_ sender: Any) {
        let url = URL(string: "http://www.jolt.rocks")
        UIApplication.shared.openURL(url!)
        self.touchOutsideMenuView()
    }
    
    @IBAction func onClickSubmitSong(_ sender: Any) {
        let url = URL(string: "http://www.jolt.rocks/submit")
        UIApplication.shared.openURL(url!)        
        self.touchOutsideMenuView()
    }
    
    @IBAction func onClickSettings(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView") as! SettingsViewController
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func onClickActiveItem(_ sender: Any) {
        if self.menuView.isHidden == false {
            self.touchOutsideMenuView()
            return
        }
        if imgCheck.tag == 0 {
            imgCheck.image = UIImage(named: "checked")
            imgCheck.tag = 1
            alarmItem?.actived = true
        } else {
            imgCheck.image = UIImage(named: "unchecked")
            imgCheck.tag = 0
            alarmItem?.actived = false
        }
    }
    @IBAction func onClickSetTimeItem(_ sender: Any) {
        if self.menuView.isHidden == false {
            self.touchOutsideMenuView()
            return
        }
        
        self.timePicker_view.isHidden = false
        
    }
    
    @IBAction func onClickRepeatItem(_ sender: Any) {
        if self.menuView.isHidden == false {
            self.touchOutsideMenuView()
            return
        }
        
        if (tapGesture_underView == nil) {
            let aSelector : Selector = #selector(DetailViewController.touchInSideUnderView)
            
            tapGesture_underView = UITapGestureRecognizer(target: self, action: aSelector)
            tapGesture_underView.numberOfTapsRequired = 1
        }
        self.underView.addGestureRecognizer(tapGesture_underView)
        
        itemKind = 1
        self.lbltitle_itemView.text = "Repeat"
        UIView.animate(withDuration: 0.7, delay: 0.0, animations: {
            self.underView.isHidden = false
            self.itemView.isHidden = false
            self.item_tableView.reloadData()
        }, completion: nil)
    }
    
    @IBAction func onClickSnoozeItem(_ sender: Any) {
        if self.menuView.isHidden == false {
            self.touchOutsideMenuView()
            return
        }
        
        if (tapGesture_underView == nil) {
            let aSelector : Selector = #selector(DetailViewController.touchInSideUnderView)
            
            tapGesture_underView = UITapGestureRecognizer(target: self, action: aSelector)
            tapGesture_underView.numberOfTapsRequired = 1
        }
        self.underView.addGestureRecognizer(tapGesture_underView)
        
        self.underView.isHidden = false
        self.snoozeView.isHidden = false
        self.edSnoozeTime.text = self.lblSnoozeTime.text
    }
    
    @IBAction func onClickBackupItem(_ sender: Any) {
        if self.menuView.isHidden == false {
            self.touchOutsideMenuView()
            return
        }
        
        if (tapGesture_underView == nil) {
            let aSelector : Selector = #selector(DetailViewController.touchInSideUnderView)
            
            tapGesture_underView = UITapGestureRecognizer(target: self, action: aSelector)
            tapGesture_underView.numberOfTapsRequired = 1
        }
        self.underView.addGestureRecognizer(tapGesture_underView)
        
        itemKind = 2
        self.lbltitle_itemView.text = "Backup Ringtone"
        self.item_tableView.reloadData()
        
        UIView.animate(withDuration: 0.7, delay: 0.0, animations: {
            self.underView.isHidden = false
            self.itemView.isHidden = false
        }, completion: nil)
    }
    @IBAction func onTimePickerDone(_ sender: Any) {
        self.timePicker_view.isHidden = true
        let timeInterval = floor(timePicker.date.timeIntervalSinceReferenceDate / 60.0) * 60.0
        let wd = NSDate(timeIntervalSinceReferenceDate: timeInterval) as Date!
        let dateFormatter: DateFormatter = DateFormatter()
        if (timeformat == true) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "hh:mm a"
        }
        let selectedTime: String = dateFormatter.string(from: wd!)
        lblTime.text = selectedTime
        alarmItem?.deadline = wd!
    }
    @IBAction func onCloseUnderView(_ sender: Any) {
        self.touchInSideUnderView()
    }
    @IBAction func onOKSnoozeTime(_ sender: Any) {
        if Int(self.edSnoozeTime.text!) == nil {
            return
        }
        self.underView.isHidden = true
        self.snoozeView.isHidden = true
        
        self.lblSnoozeTime.text = String(Int(self.edSnoozeTime.text!)!)
        alarmItem?.snoozetime = Int(self.edSnoozeTime.text!)!
        self.edSnoozeTime.endEditing(true)
    }
}
