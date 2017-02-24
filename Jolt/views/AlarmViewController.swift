//
//  AlarmViewController.swift
//  Jolt
//
//  Created by user on 12/23/16.
//  Copyright © 2016 user. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD
import AudioToolbox

class AlarmViewController: UIViewController {
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblSongName: UILabel!
    @IBOutlet weak var imgArt: UIImageView!
    @IBOutlet weak var txtDescription: UITextView!
    
    let SONG_DATA_URL:String = "https://jolt-server.herokuapp.com/songs/json"
    var player = AVPlayer()
    var alarmInfo: AlarmJsonInfo = AlarmJsonInfo()
    var infoId: Int = 0
    var snoozeTime: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        
        alarmInfo = AlarmList.sharedInstance.getAlarmInfo()
        
        // Do any additional setup after loading the view.
        DispatchQueue.main.async(execute: { 
            self.loadSongDataFromServer()
        })
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AlarmList.sharedInstance.reScheduleAlarm(snoozeTime: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadSongDataFromServer() {
        let url: NSURL = NSURL(string: SONG_DATA_URL)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
        
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest,completionHandler: {(data,response,error) in
            do {
                if (data == nil) {
                    DispatchQueue.main.async(execute: {
                        MBProgressHUD.hide(for: self.view, animated: true)
                    })
                    return
                }
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    self.infoId = jsonResult["id"] as! Int
                    DispatchQueue.main.sync(execute: {
                        // send notification for alarm
                        let AlarmNotification = UILocalNotification()
                        AlarmNotification.alertBody = (jsonResult["title"] as? String)! + " - " + (jsonResult["artist"] as? String)!
                        AlarmNotification.alertAction = "Open"
                        //notification.fireDate = alarmItem?.deadline
                        AlarmNotification.soundName = UILocalNotificationDefaultSoundName//self.currentAlarmSongUrl()
                        
                        AlarmNotification.userInfo = ["message" : (jsonResult["title"] as? String)! + " - " + (jsonResult["artist"] as? String)!]
                        AlarmNotification.applicationIconBadgeNumber = 0
                        AlarmNotification.timeZone = NSTimeZone.default
                        AlarmNotification.fireDate = Date()
                        UIApplication.shared.scheduleLocalNotification(AlarmNotification)
                    })
                    
                    if jsonResult["id"] as! Int == self.alarmInfo.infoId {
                        DispatchQueue.main.sync(execute: {
                            self.txtDescription.attributedText = self.alarmInfo.descriptionInfo
                            self.imgArt.image = self.getImageFromLocal()
                            self.lblArtist.text = self.alarmInfo.artistInfo
                            self.lblSongName.text = self.alarmInfo.titleInfo
                            self.play()
                        })
                    } else {
                        if self.currentSongDescription() != "" {
                            let descripiton:String = self.currentSongDescription()
                            let attrString: NSAttributedString = try NSAttributedString(data: descripiton.data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType], documentAttributes: nil)
                            
                            let newString = NSMutableAttributedString(attributedString: attrString)
                            let range = NSMakeRange(0, newString.length)
                            let replacementFont: UIFont = .systemFont(ofSize: 16.0)
                            newString.removeAttribute(NSFontAttributeName, range: range)
                            newString.addAttribute(NSFontAttributeName, value: replacementFont, range: range)
                            
                            DispatchQueue.main.sync(execute: {
                                self.txtDescription.attributedText = newString
                                self.alarmInfo.descriptionInfo = newString
                            })
                        }
                        
                        let imgUrl:String = (jsonResult["image_url"] as? String)!
                        let songUrl:String = (jsonResult["song_url"] as? String)!
                        
                        if imgUrl != "" && imgUrl != self.currentImgUrl() {
                            let url = URL(string: imgUrl)
                            let data = NSData(contentsOf:url! as URL)
                            
                            if data != nil {
                                self.updateImgUrl(strImgUrl: imgUrl)
                                let image = UIImage(data: data! as Data)
                                self.downloadImageFromURL(image: image!)
                                let localimage = self.getImageFromLocal()
                                DispatchQueue.main.sync(execute: {
                                    self.imgArt.contentMode = .scaleAspectFit
                                    self.imgArt.image = localimage
                                    self.alarmInfo.imageInfo = url!
                                })
                            }
                        }
                        else{
                            DispatchQueue.main.sync(execute: {
                                self.imgArt.contentMode = .scaleAspectFit
                                self.imgArt.image = self.getImageFromLocal()
                            })
                        }
                        
                        if self.currentSongArtist() != "" {
                            DispatchQueue.main.sync(execute: {
                                self.lblArtist.text = self.currentSongArtist()
                                self.alarmInfo.artistInfo = self.currentSongArtist()
                            })
                        }
                        
                        if self.currentSongTitle() != "" {
                            DispatchQueue.main.sync(execute: {
                                self.lblSongName.text = self.currentSongTitle()
                                self.alarmInfo.titleInfo = self.currentSongTitle()
                            })
                        }
                        
                        if songUrl != "" && songUrl != self.currentSongUrl() {
                            DispatchQueue.main.sync(execute: {
                                self.downloadFileFromURL(url: songUrl)
                            })
                        }
                        else{
                            DispatchQueue.main.sync(execute: {
                                self.play()
                            })
                        }
                    }
                }
            } catch let error as NSError {
                DispatchQueue.main.sync(execute: {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    return
                })
                print(error.localizedDescription)
            }
            
        }
        )
        
        dataTask.resume()
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


    func downloadImageFromURL(image: UIImage) {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("jolt_image.png")
            if let pngImageData = UIImagePNGRepresentation(image) {
                try pngImageData.write(to: fileURL, options: .atomic)
            }
        } catch { }
    }
        
    func getImageFromLocal() -> UIImage! {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsURL.appendingPathComponent("jolt_image.png").path
        if FileManager.default.fileExists(atPath: filePath) {
            return UIImage(contentsOfFile: filePath)!
        }
        return nil
    }
    
    func downloadFileFromURL(url: String){
        let song_url = URL(string:url)
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: song_url! as URL, completionHandler: { (URL, response, error) -> Void in
            guard let location = URL, error == nil else {
                DispatchQueue.main.async(execute: {
                    MBProgressHUD.hide(for: self.view, animated: true)
                })
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
                self.updateSongUrl(strSongUrl: url)
                print("File moved to documents folder")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            DispatchQueue.main.sync(execute: {
                
                self.play()
            })
            
        })
        
        downloadTask.resume()
      //  MBProgressHUD.hide(for: self.view, animated: true)
        
    }
    
    func play() {
        MBProgressHUD.hide(for: self.view, animated: true)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsURL.appendingPathComponent("jolt_song.mp3")
        
        
        do {
            let playerItem = AVPlayerItem( url: filePath )
            NotificationCenter.default.addObserver(self, selector: #selector(AlarmViewController.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
            
            DispatchQueue.global(qos: .background).async {
                self.player = AVPlayer(playerItem: playerItem)
                //player.prepareToPlay()
                self.player.rate = 1.0
                self.player.play()
                
            }
            //self.alarmInfo.songInfo = url
            self.alarmInfo.infoId = self.infoId
            AlarmList.sharedInstance.setAlarmInfo(info: alarmInfo)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
    }
    
    func playerDidFinishPlaying() {
        AlarmList.sharedInstance.setPlayStatus(val: false)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func onClickDismiss(_ sender: Any) {
        AlarmList.sharedInstance.setPlayStatus(val: false)
        self.navigationController!.popToRootViewController(animated: true)
//        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc = mainStoryboard.instantiateViewController(withIdentifier: "rootView") 
//        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func onClickSnooze(_ sender: Any) {
        let message: String = "Alarm will sound in " + String(snoozeTime) + " Minutes"
        let alertController = UIAlertController(title: "Jolt Alarm", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in
            self.player.pause()
            //self.player = nil
            AlarmList.sharedInstance.reScheduleAlarm(snoozeTime: self.snoozeTime)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "statusView") as! StatusViewController
            var date = Date()
            date.addTimeInterval(TimeInterval(Int(self.snoozeTime * 60)))
            AlarmList.sharedInstance.setSnoozeTime(val: date)
            AlarmList.sharedInstance.setSnoozeStatus(val: true)
            
            vc.alarmTime = AlarmList.sharedInstance.getEarliestAlarmDate()
            self.navigationController!.pushViewController(vc, animated: true)

        }
        alertController.addAction(okAction)
        AlarmList.sharedInstance.setPlayStatus(val: false)
        self.present(alertController, animated: true, completion: nil)
        
    }
}
