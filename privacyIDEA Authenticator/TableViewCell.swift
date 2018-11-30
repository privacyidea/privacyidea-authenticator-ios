//
//  TableViewCell.swift
//  test
//
//  Created by Nils Behlen on 08.08.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import UIKit
import SwiftOTP

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var btn_next: UIButton!
    @IBOutlet weak var lbl_name: UILabel!
    @IBOutlet weak var lbl_otp: UILabel!
   
    @IBOutlet weak var progress_view: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    // Setup for new cells - called from the TableViewController
    func setupCell(_ t: Token, _ index : Int){
        // set the row's index as tag for the button to later identify which one was tapped
        btn_next.tag = index
        
        // convert Token.algorithm to OTPAlgorithm
        var algo: OTPAlgorithm = .sha1 // default
        if t.algorithm == "sha256" { algo = .sha256 }
        else if (t.algorithm == "sha512") { algo = .sha512 }
        
        if t.type == "hotp" {
            let x = HOTP(secret: t.secret, digits: t.digits, algorithm: algo)!
            // force unwrap counter here, it's check on Token object creation
            lbl_otp.text = x.generate(counter: UInt64(t.counter!))
            
            // set visibility
            btn_next.isHidden = false
            progress_view.isHidden = true
        }
        else {
            // force unwrap interval here, it's checked on Token object creation
            let x = TOTP(secret: t.secret, digits: t.digits, timeInterval: t.period!, algorithm: algo)!
            let date = Int(Date().timeIntervalSince1970)
            lbl_otp.text = x.generate(secondsPast1970: date)
            
            // set visibility
            btn_next.isHidden = true
            progress_view.isHidden = false
        }
        lbl_name.text = t.label
    }
    
    func refreshOTP(t:Token){
        
    }
    
    /**
    Update the progressbar of the corresponding TOTP token to the given time
     -parameters:
        -t: The token to update the progress for
        -time: The time in seconds (0-30 or 0-60)
     */
    func updateProgress(t:Token, time:Int){
        if(t.type == "hotp"){return}
        //print("progress: \(time)")
        var progress:Float
        var time2:Float = Float(time)

        if t.period == 30 {
            if time2 > 30 {
                time2 -= 30
            }
            progress = time2 / 30
        } else {
            progress = time2 / 60
        }
        progress_view.setProgress(progress, animated: true)
    }
    
}
