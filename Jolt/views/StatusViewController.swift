//
//  StatusViewController.swift
//  Jolt
//
//  Created by user on 2/1/17.
//  Copyright © 2017 user. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class StatusViewController: UIViewController {
    
    var avPlayer: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    var paused: Bool = false
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var curr_Time: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    var alarmTime: Date!
    var timer = Timer()
    var timeformat: Bool!
    
    override func viewDidLoad() {
        
        let theURL = Bundle.main.url(forResource:"backvideo", withExtension: "mp4")
        
        avPlayer = AVPlayer(url: theURL!)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        avPlayer.volume = 0
        avPlayer.actionAtItemEnd = .none
        
        avPlayerLayer.frame = view.layer.bounds
        view.backgroundColor = .clear
        view.layer.insertSublayer(avPlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer.currentItem)
        
        slider.setValue(Float(UIScreen.main.brightness), animated: true)
        
        
        // set time
        timeformat = AlarmList.sharedInstance.getAlarmTimeFormat()
        let dateFormatter: DateFormatter = DateFormatter()
        if (timeformat == true) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "hh:mm a"
        }
        
        lblTime.text = dateFormatter.string(from: alarmTime)
        updateCounter()
        timer = Timer.scheduledTimer(timeInterval: 5, target:self, selector: #selector(StatusViewController.updateCounter), userInfo: nil, repeats: true)
    }
    
    func playerItemDidReachEnd(notification: Notification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: kCMTimeZero)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async(execute: {
            self.avPlayer.play()
        })
        paused = false
        
        // charge toast
        UIDevice.current.isBatteryMonitoringEnabled = true
        let currentState = UIDevice.current.batteryState
        if (!(currentState == UIDeviceBatteryState.charging || currentState == UIDeviceBatteryState.full)) {
            self.view.makeToast("Please connect charger", duration: 10.0, position: .bottom)
            //self.window?.showToast(self.window!)
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.avPlayer.pause()
        timer.invalidate()
        paused = true
    }
    
    func updateCounter() {
        let dateFormatter: DateFormatter = DateFormatter()
        if (timeformat == true) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "hh:mm a"
        }
        curr_Time.text = dateFormatter.string(from: Date())
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    @IBAction func onChangedSlider(_ sender: Any) {
        UIScreen.main.brightness = CGFloat(slider.value)
    }
}
