//
//  SettingsViewController.swift
//  ProCamera
//
//  Created by Hao Wang on 3/8/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit


class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, settingsDelegate {
    
    private let settings = [
        "Grid",
        "Geo Tagging",
        "Lossless Quality"
    ]
    var settingsValue: [String: Bool] = [String: Bool]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.view.window?.reloadInputViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let settingsValueTmp = NSUserDefaults.standardUserDefaults().objectForKey("settingsStore") as? [String: Bool]
        if settingsValueTmp != nil {
            settingsValue = settingsValueTmp!
        } else {
            settingsValue = [String: Bool]()
        }
        println("\(settingsValue) View did load")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("settingsUpdatedNotification", object: nil, userInfo: self.settingsValue)
        })
    }
    
    func changeSetting(name: String, value: Bool) {
        switch name {
        case settings[0], settings[1], settings[2]:
            settingsValue[name] = value
        default:
            let x = 1
        }
        println("\(self.settingsValue) changeSetting")
        //set data
        NSUserDefaults.standardUserDefaults().setObject(settingsValue, forKey: "settingsStore")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        println("\(self.settingsValue) cellForRowAtIndexPath")
        if indexPath.row < 4 {
            var cell = tableView.dequeueReusableCellWithIdentifier("settingBoolCell") as SettingBoolTableViewCell
            var on: Bool? = self.settingsValue[settings[indexPath.row]]
            if on == nil {
                on = false
            }
            cell.switchBtn.setOn(on!, animated: true)
            cell.settingName.text = settings[indexPath.row]
            cell.delegate = self
            return cell
        } else {
            var cell = tableView.dequeueReusableCellWithIdentifier("settingOptionsCell") as SettingOptionsTableViewCell
            cell.settingName.text = settings[indexPath.row]
            cell.optionVal.text = "Default" //place holder
            return cell
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
