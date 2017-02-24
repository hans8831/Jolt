//
//  ViewController.swift
//  Jolt
//
//  Created by user on 12/22/16.
//  Copyright © 2016 user. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class AlarmTableViewCell: UITableViewCell {
    @IBOutlet weak var btnActive: UIButton!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var alarm_tableView: UITableView!
    @IBOutlet weak var btnViewStatus: UIButton!
    
    var tapGesture:UITapGestureRecognizer!
    var alarmItems: [AlarmItem] = []
    var timeformat: Bool = false
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadMusicFromServer()
        alarm_tableView.delegate = self
        alarm_tableView.dataSource = self
        timeformat = AlarmList.sharedInstance.getAlarmTimeFormat()
        
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showAlarmView), name: NSNotification.Name(rawValue: "ShowAlarm"), object: nil)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: nil)
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    let SONG_DATA_URL:String = "https://jolt-server.herokuapp.com/songs/json"
    func downloadMusicFromServer(){
        let url: NSURL = NSURL(string: SONG_DATA_URL)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
        
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest,completionHandler: {(data,response,error) in
            do {
                if (data == nil) {
                    return
                }
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    let imgUrl:String = (jsonResult["image_url"] as? String)!
                    let songUrl:String = (jsonResult["song_url"] as? String)!
                    let songDescription:String = (jsonResult["description"] as? String)!
                    let songArtist:String = (jsonResult["artist"] as? String)!
                    let songTitle:String = (jsonResult["title"] as? String)!

                    if songUrl != "" && songUrl != self.currentSongUrl() {
                        DispatchQueue.main.sync(execute: {
                            self.downloadFileFromURL(url: songUrl)
                        })
                    }

                    if imgUrl != "" && imgUrl != self.currentImgUrl() {
                        let url = URL(string: imgUrl)
                        let data = NSData(contentsOf:url! as URL)
                        
                        if data != nil {
                            self.updateImgUrl(strImgUrl: imgUrl)
                            let image = UIImage(data: data! as Data)
                            self.downloadImageFromURL(image: image!)
                        }
                    }
                    
                    if songDescription != self.currentSongDescription() {
                        self.updateSongDescription(strSongDescription: songDescription)
                    }
                    
                    if songArtist != self.currentSongArtist() {
                        self.updateSongArtist(strSongArtist: songArtist)
                    }
                    
                    if songTitle != self.currentSongTitle() {
                        self.updateSongArtist(strSongArtist: songTitle)
                    }
                }
            } catch let error as NSError {
                DispatchQueue.main.sync(execute: {
                    return
                })
                print(error.localizedDescription)
            }
        }
        )
        
        dataTask.resume()
    }
    
    func downloadImageFromURL(image: UIImage) {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("jolt_image.png")
            if let pngImageData = UIImagePNGRepresentation(image) {
                try pngImageData.write(to: fileURL, options: .atomic)
            }
        } catch { }
    }
    
    func downloadFileFromURL(url: String){
        let song_url = URL(string:url)
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: song_url! as URL, completionHandler: { (URL, response, error) -> Void in
            guard let location = URL, error == nil else {
                return
            }
            // then lets create your document folder url
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // lets create your destination file url
            let destinationUrl = documentsDirectoryURL.appendingPathComponent("jolt_song.mp3")
            print(destinationUrl)
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                do{
                    try FileManager.default.removeItem(atPath: destinationUrl.path)
                }catch{
                    print("Handle Exception")
                }
            }
            // you can use NSURLSession.sharedSession to download the data asynchronously
            do {
                // after downloading your file you need to move it to your destination url
                try FileManager.default.moveItem(at: location, to: destinationUrl)
                
                print(destinationUrl.absoluteString)
                self.updateAlarmSongUrl(strAlarmSongUrl: destinationUrl.absoluteString)
                self.updateSongUrl(strSongUrl: url)
                print("File moved to documents folder")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        })
        
        downloadTask.resume()
    }
    
    func currentAlarmSongUrl() -> String{
        if (UserDefaults.standard.string(forKey: "alarmSongUrl") != nil){
            return UserDefaults.standard.string(forKey: "alarmSongUrl")!
        }
        return ""
    }
    
    func updateAlarmSongUrl(strAlarmSongUrl: String){
        UserDefaults.standard.setValue(strAlarmSongUrl, forKey: "alarmSongUrl")
    }
    
    func currentSongUrl() -> String{
        if (UserDefaults.standard.string(forKey: "songUrl") != nil){
            return UserDefaults.standard.string(forKey: "songUrl")!
        }
        return ""
    }
    
    func updateSongUrl(strSongUrl: String){
        UserDefaults.standard.setValue(strSongUrl, forKey: "songUrl")
    }
    
    func currentImgUrl() -> String{
        if(UserDefaults.standard.string(forKey: "imgUrl") != nil){
            return UserDefaults.standard.string(forKey: "imgUrl")!
        }
        return ""
    }
    
    func updateImgUrl(strImgUrl: String){
        UserDefaults.standard.setValue(strImgUrl, forKey: "imgUrl")
    }
    
    func currentSongDescription() -> String{
        if(UserDefaults.standard.string(forKey: "songDescription") != nil){
            return UserDefaults.standard.string(forKey: "songDescription")!
        }
        return ""
    }

    func updateSongDescription(strSongDescription: String){
        UserDefaults.standard.setValue(strSongDescription, forKey: "songDescription")
    }

    func currentSongTitle() -> String{
        if(UserDefaults.standard.string(forKey: "songTitle") != nil){
            return UserDefaults.standard.string(forKey: "songTitle")!
        }
        return ""
    }
    
    func updateSongTitle(strSongTitle: String){
        UserDefaults.standard.setValue(strSongTitle, forKey: "songTitle")
    }
    
    func currentSongArtist() -> String{
        if(UserDefaults.standard.string(forKey: "songArtist") != nil){
            return UserDefaults.standard.string(forKey: "songArtist")!
        }
        return ""
    }
    
    func updateSongArtist(strSongArtist: String){
        UserDefaults.standard.setValue(strSongArtist, forKey: "songArtist")
    }
    
    func resetTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(
            timeInterval: 60, target: self, selector: #selector(ViewController.showViewStatus), userInfo: nil, repeats: false)
    }
    
    func showViewStatus() {
        if self.btnViewStatus.isHidden == false {
            self.onViewStatusPage(sender:self)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        resetTimer()
        return false
    }
    
    func touchOutsideMenuView(){
        self.menuView.isHidden = true
        if tapGesture != nil {
            view.removeGestureRecognizer(tapGesture)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.menuView.isHidden = true
        timeformat = AlarmList.sharedInstance.getAlarmTimeFormat()
        alarmItems = AlarmList.sharedInstance.allItems()
        self.btnViewStatus.isHidden = true
        for item in alarmItems {
            if item.actived {
                self.btnViewStatus.isHidden = false
            }
        }
        
//        if (AlarmList.sharedInstance.getSnoozeStatus() == true) {
//            if (AlarmList.sharedInstance.getSnoozeTime() > Date()) {
//                self.btnViewStatus.isHidden = false
//            }
//        }
    
        alarm_tableView.reloadData()
        resetTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.timer?.invalidate()
        self.touchOutsideMenuView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarmItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AlarmTableViewCell
        
        let item: AlarmItem = alarmItems[indexPath.row] as AlarmItem
        let dateFormatter: DateFormatter = DateFormatter()
        if (timeformat == true) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "hh:mm a"
        }
        cell.lblTime.text = dateFormatter.string(from: item.deadline)
        cell.lblDate.text = item.repeatMode
        cell.btnActive.tag = indexPath.row
        
        if item.actived == true {
            cell.btnActive.setImage(UIImage(named: "checked"), for: UIControlState.normal)
        } else {
            cell.btnActive.setImage(UIImage(named: "unchecked"), for: UIControlState.normal)
        }
        
        cell.btnActive.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControlEvents.touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.timer?.invalidate()
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
        //let vc = mainStoryboard.instantiateViewController(withIdentifier: "alarmView") as! AlarmViewController
        AlarmList.sharedInstance.setSelectedIndex(index: indexPath.row)
        self.navigationController!.pushViewController(vc, animated: true)
        //self.present(vc, animated: false, completion: nil)

    }
    
    func buttonClicked(sender:UIButton) {
        if (sender.tag > -1)
        {
            var item: AlarmItem = alarmItems[sender.tag] as AlarmItem
            item.actived = !item.actived
            
            if item.actived == true {
                sender.setImage(UIImage(named: "checked"), for: UIControlState.normal)
                var date: Date = item.deadline
                let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
                
                var interval = date.timeIntervalSince(Date())
                
                while (interval < TimeInterval(-60*60*24)) {
                    date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: date, options:.matchStrictly)!
                    interval = date.timeIntervalSince(Date())
                }
                
                if item.repeatMode != "" {
                    var scheduleDate: Date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 7, to: item.deadline, options:.matchStrictly)!
                    
                    let datesForNotification = AlarmList.sharedInstance.correctDate(item.deadline, onWeekdaysForNotify:item.repeatMode)
                    
                    for d in datesForNotification
                    {
                        if( d < scheduleDate && d > Date()) {
                            scheduleDate = d
                        }
                    }
                    date = scheduleDate
                } else {
                    date = item.deadline
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
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                sender.setImage(UIImage(named: "unchecked"), for: UIControlState.normal)
            }
            AlarmList.sharedInstance.updateItem(item: item, index: sender.tag)
            alarmItems = AlarmList.sharedInstance.allItems()
            
            self.btnViewStatus.isHidden = true
            for item in alarmItems {
                if item.actived {
                    self.btnViewStatus.isHidden = false
                }
            }
            if (AlarmList.sharedInstance.getSnoozeStatus() == true) {
                if (AlarmList.sharedInstance.getSnoozeTime() > Date()) {
                    self.btnViewStatus.isHidden = false
                }
            }
            
            AlarmList.sharedInstance.reScheduleAlarm(snoozeTime: 0)
        }
    }
    
    func showAlarmView() {
        self.timer?.invalidate()
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "alarmView") as! AlarmViewController
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func onViewStatusPage(_ sender: Any) {
        if (alarmItems.count > 0) {
            let item: AlarmItem = alarmItems[0] as AlarmItem
            if item.actived == false {
                return
            }
            self.timer?.invalidate()
            let date = AlarmList.sharedInstance.getEarliestAlarmDate()
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "statusView") as! StatusViewController
            vc.alarmTime = date
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func onAdd(_ sender: Any) {
        self.timer?.invalidate()
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
        AlarmList.sharedInstance.setSelectedIndex(index: -1)
        
        //self.present(vc, animated: false, completion: nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }

    @IBAction func onShowMenu(_ sender: Any) {
        if (tapGesture == nil) {
            let aSelector : Selector = #selector(ViewController.touchOutsideMenuView)
            
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
    @IBAction func onClickSubmit(_ sender: Any) {
        let url = URL(string: "http://www.jolt.rocks/submit")
        UIApplication.shared.openURL(url!)        
        self.touchOutsideMenuView()
    }
    @IBAction func onClickSettings(_ sender: Any) {
        self.timer?.invalidate()
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView") as! SettingsViewController
        self.navigationController!.pushViewController(vc, animated: true)
    }
}

