//
//  PictureStyleViewController.swift
//  ProCamera
//
//  Created by Hao Wang on 3/8/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class PictureStyleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let pictureStyles = ["Sharpness", "Contrast", "Saturation", "Color Tone"]

    @IBOutlet weak var tableView: UITableView!
    @IBAction func onClose(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier("pictureStyleCell") as PictureStyleTableViewCell
            cell.nameLabel.text = pictureStyles[indexPath.row]
            return cell
        } else {
            //handle presets
            var cell = tableView.dequeueReusableCellWithIdentifier("presetCell") as PresetTableViewCell
            cell.presetName.text = "Default" // Placeholder
            return cell
        }
        
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Picture Style"
        case 1:
            return "Presets"
        default:
            return ""
        }
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
