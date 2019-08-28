//
//  EnterDetailController.swift
//  test
//
//  Created by Nils Behlen on 24.08.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import UIKit

class EnterDetailController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var secretTF: UITextField!
    
    @IBOutlet weak var encodingSeg: UISegmentedControl!     // 0-Normal, 1-Base32, 2-Hex
    @IBOutlet weak var typeSeg: UISegmentedControl!         // 0-HOTP, 1-TOTP
    @IBOutlet weak var digitSeg: UISegmentedControl!        // 0-6, 1-8
    @IBOutlet weak var algorithmSeg: UISegmentedControl!    // 0-SHA1, 1-SHA256, 2-SHA512
    @IBOutlet weak var periodSeg: UISegmentedControl!       // 0-30s, 1-60s
    
    let types = ["hotp", "totp"]
    let digits = [6,8]
    let algorithms = ["sha1","sha256","sha512"]
    let periods = [30,60]
    
    var presenterDelegate: PresenterDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        periodSeg.isHidden = true
        typeSeg.addTarget(self, action: #selector(typeChanged), for: UIControl.Event.valueChanged)
        
        // Set delegate of textfields to respond to pressing 'return' on keyboard
        nameTF.delegate = self
        secretTF.delegate = self
        // check for taps to close the keyboard
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }
    
    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func typeChanged(sender: UISegmentedControl){
        sender.selectedSegmentIndex == 0 ? (periodSeg.isHidden = true) : (periodSeg.isHidden = false)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        
        sender.isEnabled = false
        let name = nameTF.text!
        var secret = secretTF.text!.data(using: String.Encoding.utf8)
        let type = types[typeSeg.selectedSegmentIndex]
        let digit = digits[digitSeg.selectedSegmentIndex]
        let algorithm = algorithms[algorithmSeg.selectedSegmentIndex]
        let period = periods[periodSeg.selectedSegmentIndex]
        
        switch encodingSeg.selectedSegmentIndex {
        case 1: // Base32
            let text = secretTF.text!
            if text.base32DecodedData != nil {
                secret = text.base32DecodedData!
            } else {
                sender.isEnabled = true
                let alert = UIAlertController(title: NSLocalizedString("error_title", comment: "error dialog title"), message: NSLocalizedString("secret_not_b32_dialog_text", comment: "The secret is not a valid base32 string"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                return
            }
            break
        case 2: // Hex
            secret = Data(hex: secretTF.text!)
            break
        default: // Normal
            break
        }
        
        let t = Token(type: type, label: name,serial: name, digits: digit, algorithm: algorithm, secret: secret!, counter: 1, period: period)
        presenterDelegate?.addManuallyFinished(token: t)
        navigationController?.popViewController(animated: true)
    }
    
}
