 //
//  AppDelegate.swift
//  Jolt
//
//  Created by user on 12/22/16.
//  Copyright © 2016 user. All rights reserved.
//

import UIKit
import UserNotifications
import BRYXBanner
import Toast_Swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIGestureRecognizerDelegate {

    var window: UIWindow?
   

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        application.beginBackgroundTask(withName: "ShowAlarm", expirationHandler: nil)
        
        if ((launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification) != nil) {
            let notification: UILocalNotification = (launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification)!
            application.applicationIconBadgeNumber = 0
            //if (localNotificationInfo.userInfo!["yourKey"] as? String) != nil {
                if ((notification.userInfo?.count)! > 1 ){
                    let rootViewController = self.window!.rootViewController as! UINavigationController
                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = mainStoryboard.instantiateViewController(withIdentifier: "alarmView") as! AlarmViewController
                    let txtSnooze = notification.userInfo?["snooze"] as! String
                    vc.snoozeTime = Int(txtSnooze)!
                    //self.window?.rootViewController = vc
                    //rootViewController.present(vc, animated: false, completion: nil)
                    // charge toast
                    UIDevice.current.isBatteryMonitoringEnabled = true
                    let currentState = UIDevice.current.batteryState
                    if (!(currentState == UIDeviceBatteryState.charging || currentState == UIDeviceBatteryState.full)) {
                        self.window?.makeToast("Please connect charger", duration: 10.0, position: .bottom)
                        //self.window?.showToast(self.window!)
                    }
                    
                    rootViewController.pushViewController(vc, animated: true)
                }
            //}
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowAlarm"), object: self)
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
            UIApplication.shared.applicationIconBadgeNumber = 0
            let rootViewController = self.window!.rootViewController as! UINavigationController
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "alarmView") as! AlarmViewController
            vc.snoozeTime = 10
            rootViewController.pushViewController(vc, animated: true)
        }
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        if ((notification.userInfo?.count)! > 1 ){
            DispatchQueue.global(qos: .background).async {
                while (true) {
                    if (AlarmList.sharedInstance.getPlayStatus() == false) {
                        DispatchQueue.main.sync(execute: {
                            AlarmList.sharedInstance.setPlayStatus(val: true)
                            let rootViewController = self.window!.rootViewController as! UINavigationController
                            let lastViewController = rootViewController.viewControllers.last! as UIViewController
                            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = mainStoryboard.instantiateViewController(withIdentifier: "alarmView") as! AlarmViewController
                            let txtSnooze = notification.userInfo?["snooze"] as! String
                            vc.snoozeTime = Int(txtSnooze)!
                            
                            // charge toast
                            UIDevice.current.isBatteryMonitoringEnabled = true
                            let currentState = UIDevice.current.batteryState
                            if (!(currentState == UIDeviceBatteryState.charging || currentState == UIDeviceBatteryState.full)) {
                                self.window?.makeToast("Please connect charger", duration: 10.0, position: .bottom)
                                //self.window?.showToast(self.window!)
                            }
                            
                            lastViewController.navigationController?.pushViewController(vc, animated: true)
                            
                        })
                        break
                    }
                    usleep(30000)
                }
            }
        } else {
            let banner = Banner(title: "Jolt", subtitle: notification.userInfo?["message"] as? String, image: UIImage(named: "icon"), backgroundColor: UIColor(red:10.00/255.0, green:12.0/255.0, blue:33/255.0, alpha:0.5))
            banner.shouldTintImage = false
            banner.dismissesOnTap = true
            banner.show(duration: 3.0)
        }
        
//        rootViewController.pushViewController(vc, animated: true)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Info = ",notification.request.content.userInfo)
        completionHandler([UNNotificationPresentationOptions.alert, UNNotificationPresentationOptions.badge, UNNotificationPresentationOptions.sound])
    }
    
    //Called to let your app know which action was selected by the user for a given notification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User Info = ",response.notification.request.content.userInfo)
        completionHandler()
    }
    
//    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
//        NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowAlarm"), object: self)
//        
//    }
}

