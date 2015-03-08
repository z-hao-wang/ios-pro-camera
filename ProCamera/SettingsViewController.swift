//
//  SettingsViewController.swift
//  ProCamera
//
//  Created by Hao Wang on 3/8/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let settings = [
        "Grid",
        "Zoom",
        "Sound",
        "Geo Tagging",
        "Quality",
        "In App Purchase",
        "Mode"
    ]

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row < 4 {
            var cell = tableView.dequeueReusableCellWithIdentifier("settingBoolCell") as SettingBoolTableViewCell
            cell.switchBtn.setOn(true, animated: true)
            cell.settingName.text = settings[indexPath.row]
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
