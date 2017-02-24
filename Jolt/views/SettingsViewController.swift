//
//  SettingsViewController.swift
//  Jolt
//
//  Created by user on 2/1/17.
//  Copyright © 2017 user. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var switchHour: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.switchHour.setOn(AlarmList.sharedInstance.getAlarmTimeFormat(), animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onSwitchHour(_ sender: Any) {
        AlarmList.sharedInstance.setAlarmTimeFormat(format: self.switchHour.isOn)
    }
    @IBAction func onBack(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
}
