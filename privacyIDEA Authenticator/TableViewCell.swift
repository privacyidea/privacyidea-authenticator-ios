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
    
    @IBOutlet weak var buttonStackV: UIButton!
    @IBOutlet weak var buttonDismissStackV: UIButton!
    @IBOutlet weak var buttonHOTP: UIButton!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var labelStackV: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelOTP: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var progressBarHeight: NSLayoutConstraint!
    
    var presenter: PresenterCellDelegate?
    
    let indicator = UIActivityIndicatorView(style: .gray)
    
    let color_text_white = [NSAttributedString.Key.foregroundColor : UIColor.white]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    // Called for new cells or when tableVC.reloadCells
    func setupCell(_ token: Token, _ index : Int) {
        
        // set the row's index as tag for the button to later identify which one was tapped
        buttonHOTP.tag = index
        buttonStackV.tag = index
        buttonDismissStackV.tag = index
        /////////////////////////////////////
        
        labelName.text = token.label
        labelName.numberOfLines = 1
        
        // Separate the OTP with a whitespace after half the digits for better readability
        if let otp = token.currentOTP {
            var step: Int
            (token.digits ?? 6) == 8 ? (step = 4)
                : (step = 3)
            labelOTP.text = String(otp.enumerated().map{ $0 > 0 && $0 % step == 0 ? [" ", $1] : [$1] }.joined())
        }
        
        // Set all other views to gone by default
        labelStackV.isHidden = true
        labelStackV.textAlignment = .left
        buttonStackV.isHidden = true
        hideStackView()
        buttonHOTP.isHidden = true
        progressBar.isHidden = true
        progressBarHeight.constant = 0
        buttonStackV.isEnabled = true
        indicator.isHidden = true
        
        if token.type == Tokentype.HOTP {
            buttonHOTP.isHidden = false
            buttonHOTP.addTarget(presenter, action: #selector(Presenter.increaseHOTP(_ :)), for: .touchUpInside)
            labelOTP.font = UIFont.boldSystemFont(ofSize: 34.0)
        }
        else if token.type == Tokentype.TOTP {
            labelOTP.font = UIFont.boldSystemFont(ofSize: 34.0)
            buttonHOTP.isHidden = true
            progressBar.isHidden = false
            progressBarHeight.constant = 5
        } else {
            // MARK: PUSH CELL
            // Reset the button target - has multiple uses
            buttonStackV.removeTarget(nil, action: nil, for: .allEvents)
            labelOTP.font = UIFont.systemFont(ofSize: 34.0)
            
            
            switch token.getState() {
            case State.FINISHED:
                // PUSH DEFAULT
                labelName.text = Constants.PUSHTOKEN_LABEL
                labelOTP.text = token.label
                
                if token.hasPendingAuths() && presenter != nil {
                    // Display the pending Auth
                    labelName.text = token.pendingAuths.first?.title
                    labelStackV.text = token.pendingAuths.first?.question
                    
                    buttonStackV.addTarget(presenter, action: #selector(Presenter.confirmedPushAuthentication(_ :)), for: .touchUpInside)
                    
                    if token.getLastestError() == nil {
                        // First try
                        let atr = NSAttributedString(string: NSLocalizedString("allow", comment: "allow button label"),
                                                     attributes: color_text_white)
                        buttonStackV.setAttributedTitle(atr, for: .normal)
                        addToStackView([labelStackV, buttonStackV])
                    } else {
                        // It is a second+ try
                        labelName.numberOfLines = 2
                        labelName.text = token.getLastestError()?.localizedDescription
                        labelOTP.text = ""
                        let atr = NSAttributedString(string: NSLocalizedString("retry", comment: "retry button label"),
                                                     attributes: color_text_white)
                        buttonStackV.setAttributedTitle(atr, for: .normal)
                        // Setup the dismiss button
                        buttonDismissStackV.addTarget(presenter, action: #selector(Presenter.dismissPushAuthentication(_:)), for:.touchUpInside)
                        addToStackView([labelStackV,buttonStackV,buttonDismissStackV])
                    }
                }
                break
                
            case State.UNFINISHED:
                labelName.text = Constants.PUSHTOKEN_LABEL + " " + NSLocalizedString(" - Rollout Unfinished", comment: "rollout unfinished label addition")
                labelOTP.text = token.label
                
                if presenter != nil {
                    if token.getLastestError() != nil {
                        labelStackV.isHidden = false
                        labelStackV.text = token.getLastestError()?.localizedDescription
                    }
                    let atr = NSAttributedString(string: NSLocalizedString("retry", comment: "retry button label"),
                                                 attributes: color_text_white)
                    buttonStackV.setAttributedTitle(atr, for: .normal)
                    buttonStackV.addTarget(presenter, action: #selector(Presenter.retryRollout(_:)), for: .touchUpInside)
                    addToStackView([labelStackV, buttonStackV])
                }
                break
                
            case State.ENROLLING:
                labelOTP.text = token.label
                labelName.text = ""
                addToStackView([labelStackV, indicator])
                indicator.startAnimating()
                labelStackV.isHidden = false
                labelStackV.text = NSLocalizedString("rolling_out", comment: "rolling out label text")
                labelStackV.textAlignment = .right
                break
                
            case State.AUTHENTICATING:
                addToStackView([labelStackV, indicator])
                indicator.startAnimating()
                labelStackV.isHidden = false
                labelStackV.textAlignment = .right
                labelStackV.text = NSLocalizedString("authenticating", comment: "authenticating label text")
                break;
                
            default: break
            }
        }
    }
    
    func showStackView() {
        stackViewHeight.constant = 40
    }
    
    func hideStackView() {
        stackViewHeight.constant = 0
    }
    
    private func addToStackView(_ views: [UIView]) {
        showStackView()
        // Clear the stackview first
        // Removing from stackview means the view is not managed by it anymore but still displayed so it has to be hidden aswell
        indicator.stopAnimating()
        let elements = stackView.arrangedSubviews
        for e in elements {
            stackView.removeArrangedSubview(e)
            e.isHidden = true
        }
        
        for e in views {
            e.isHidden = false
            stackView.addArrangedSubview(e)
        }
    }
    
    /**
     Update the progressbar of the corresponding TOTP token to the given time
     -parameters:
     -t: The token to update the progress for
     -time: The time in seconds (0-30 or 0-60)
     */
    func updateProgressbar(t:Token, time:Int) {
        if !(t.type == Tokentype.TOTP) { return }
        //U.log("progress: \(time)")
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
        if time == 0 {
            progressBar.setProgress(0, animated: false)
        } else {
            UIView.animate(withDuration: 1.2) {
                self.progressBar.setProgress(progress, animated: true)
            }
        }
    }
}
