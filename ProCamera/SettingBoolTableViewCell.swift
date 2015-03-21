//
//  SettingTableViewCell.swift
//  ProCamera
//
//  Created by Hao Wang on 3/8/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

protocol settingsDelegate {
    func changeSetting(name: String, value: Bool)
}

class SettingBoolTableViewCell: UITableViewCell {
    
    var delegate: settingsDelegate?

    @IBOutlet weak var switchBtn: UISwitch!
    @IBOutlet weak var settingName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func onChangeSwitch(sender: UISwitch) {
        delegate?.changeSetting(self.settingName.text!, value: sender.on)
    }

}
