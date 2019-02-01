//
//  TableViewController.swift
//  test
//
//  Created by Nils Behlen on 08.08.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import UIKit
import SwiftOTP
import Security
import CryptoSwift
import CommonCrypto

class TableViewController: UIViewController {
// MARK: Variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var tableViewLeadingC: NSLayoutConstraint!
    @IBOutlet weak var tableViewTrailingC: NSLayoutConstraint!
    
    var tokenlist : [Token] = []
    var util: Utilities = Utilities()
    var timer: Timer?
    
    var menuOpen: Bool = false
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var addManuallyBtn: UIButton!
    @IBOutlet weak var thirdPartyBtn: UIButton!
    @IBOutlet weak var sortBtn: UIButton!
    
// MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "privacyIDEA Authenticator"
        
        let del = UIApplication.shared.delegate as! AppDelegate
        del.tableVC = self
        
        runTimer()
        tokenlist.append(contentsOf: util.loadTokens())
        
        //////////////////////// SIDE MENU SETUP ////////////////////////
        /*menuView.isHidden = true
        let menuTap = UITapGestureRecognizer(target: self, action: #selector(TableViewController.menuTapped))
        menuView.addGestureRecognizer(menuTap)*/
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(TableViewController.menuTapped))
        leftSwipe.direction = .left
        menuView.addGestureRecognizer(leftSwipe)
        
        menuView.layer.borderColor = UIColor.black.cgColor
        menuView.layer.borderWidth = 1.0
        versionLabel.text = version()
        //////////////////////// NAVIGATION BAR SETUP ////////////////////////
        // change the color of the navigationbar, text and back button
        //self.navigationController?.navigationBar.backgroundColor = UIColor(red: 0x55 / 255.0, green: 0xb0 / 255.0, blue: 0xe6 / 255.0, alpha: 1.0)
        
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(TableViewController.addTapped))
        addBtn.tintColor = .black
        self.navigationItem.rightBarButtonItem = addBtn
        self.navigationController?.navigationBar.tintColor = .black
        
        let menuBtn = UIBarButtonItem(image: UIImage(named: "Menuicon.png"), style: .plain, target: self, action: #selector(TableViewController.menuTapped))
        menuBtn.tintColor = UIColor.black
        self.navigationItem.leftBarButtonItem = menuBtn
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scanQR" {
            let scanQRVC = segue.destination as! ScannerViewController
            // set self as delegate to receive the scanned code
            scanQRVC.qrScanDelegate = self
        }
        
        if segue.identifier == "ManualAddStart" {
            let manualAddVC = segue.destination as! EnterDetailController
            manualAddVC.tableVC = self
        }
    }
// MARK: Logic
    @IBAction func nextOTPButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        if tokenlist[index].counter != nil {
            tokenlist[index].counter! += 1
        } else { tokenlist[index].counter = 1 }
        self.tableView.reloadData()
    }
    
    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "Version \(version) build \(build)"
    }
    
    @objc func addTapped() {
        let scanQRVC = self.storyboard?.instantiateViewController(withIdentifier: "ScannerViewController") as! ScannerViewController
        scanQRVC.qrScanDelegate = self
        navigationController?.pushViewController(scanQRVC, animated: true)
    }
    
    @objc func menuTapped() {
        menuOpen = !menuOpen
        if self.menuOpen {
            self.menuView.isHidden = false
            self.menuView.isOpaque = false
            self.menuView.layer.zPosition = 1
            self.tableView.isOpaque = true
            self.tableView.alpha = 0.4
            self.tableView.isUserInteractionEnabled = false
            self.view.layoutIfNeeded()
            // switch menu icon
            let menuBtn2 = UIBarButtonItem(image: UIImage(named: "MenuiconTapped.png"), style: .plain, target: self, action:#selector(TableViewController.menuTapped))
            menuBtn2.tintColor = UIColor.black
            self.navigationItem.leftBarButtonItem = menuBtn2
        } else {
            self.menuView.isHidden = true
            self.menuView.isOpaque = true
            self.menuView.layer.zPosition = 2
            self.tableView.isOpaque = false
            self.tableView.alpha = 1.0
            self.tableView.isUserInteractionEnabled = true
                
            self.view.layoutIfNeeded()
            // switch menu icon
            let menuBtn = UIBarButtonItem(image: UIImage(named: "Menuicon.png"), style: .plain, target: self, action: #selector(TableViewController.menuTapped))
            menuBtn.tintColor = UIColor.black
            self.navigationItem.leftBarButtonItem = menuBtn
        }
       
        
        /*if !menuOpen{
            UIView.animate(withDuration: 0.3/*Animation Duration second*/, animations: {
                self.menuView.alpha = 0
            }, completion:  {
                (value: Bool) in
                self.menuView.isHidden = true
            })
        } else {
            self.menuView.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.menuView.alpha = 1
            }, completion:  nil)
        }*/
        
    }
    
    func saveTokenlist() {
        util.saveTokens(list: self.tokenlist)
    }
    
    func addToken(token: Token) {
        self.tokenlist.append(token)
        saveTokenlist()
        self.tableView.reloadData()
    }
    
    /**
        Start the timer in a background thread to update the progressbars
        and initiate the update of TOTP tokens
    */
    func runTimer()->Void {
        var seconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t) in
            seconds += 1
            if seconds > 60 {seconds = 1}
            //print(seconds)
            if (seconds < 31 && seconds > 29 || seconds > 58){
                self.tableView.reloadData()
            }
            for i in 0..<self.tokenlist.count {
                let indexPath = IndexPath(row: i, section: 0)
                let cell = self.tableView.cellForRow(at: indexPath)
                if cell != nil {
                    let cell2:TableViewCell = cell as! TableViewCell
                    cell2.updateProgress(t: self.tokenlist[i], time: seconds)
                }
            }
        }
    }
    
    @IBAction func addManuallyTapped(_ sender: Any) {
        menuTapped() // close the menu
        let aMVC = self.storyboard?.instantiateViewController(withIdentifier: "EnterDetailVC") as! EnterDetailController
        aMVC.tableVC = self
        navigationController?.pushViewController(aMVC, animated: true)
    }
    
    @IBAction func thirdPartyBtnTapped(_ sender: Any) {
        menuTapped() // close the menu
        let aboutVC = self.storyboard?.instantiateViewController(withIdentifier: "AboutVC") as! AboutViewController
        navigationController?.pushViewController(aboutVC, animated: true)
    }
    
    @IBAction func sortBtnTapped(_ sender: Any) {
        if(self.tableView.isEditing == true)
        {
            self.tableView.setEditing(false, animated: true)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(TableViewController.addTapped))
        }
        else
        {
            self.tableView.setEditing(true, animated: true)
            menuTapped()
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(TableViewController.sortBtnTapped(_:)))
        }
    }

    func refreshTokenlist() {
        self.tableView.reloadData()
    }
    
    // MARK: - 2STEP
    func do2stepinit(t:Token, salt_size:Int, difficulty:Int, output:Int) -> Token {
        // 1. Generate random bytes equal to the "salt" aka phonepart size
        var phonepart = [UInt8](repeating: 0, count: salt_size) // array to hold randoms bytes

        // Generate random bytes
        let res = SecRandomCopyBytes(kSecRandomDefault, salt_size, &phonepart)
        if res != errSecSuccess {
            print("random byte generation failed")
            // TODO handle error display something?
            return t
        }
        //print(phonepart.count)
        
        print("token secret before: \(t.secret.toHexString())")
        print("phonepart as hex: \(phonepart.toHexString())")

        // 2. PDBKDF2 with the specified parameters
        
        let password = t.secret.toHexString()
    
        let derivedKeyData: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: (output/8))
        
        let cs = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, password.count, phonepart, phonepart.count, CCPBKDFAlgorithm(kCCPRFHmacAlgSHA1), UInt32(difficulty), derivedKeyData, (output/8))
        let dat = Data(bytes: derivedKeyData, count: (output/8))
        
        print("CCKeyDerivationPBKDF result: \(cs)")
        print("complete secret: \(dat.toHexString())")
        
        t.secret = dat
        
        /* 3. Build the result to show to the user as follows:
        The first 4 characters of the sha1 hash of the client (phone's) part as checksum.
        client_part being the binary random value that the client (phone) generated:
        b32encode( sha1(client_part)[0:3] + client_part )
        '=' are removed and characters are displayed in packs of 4
        */

        let hash = phonepart.sha1()
        var chksm:Array<UInt8> = Array(hash.prefix(4))
        //let chksm_b32 = base32Encode(chksm)
        print("chksm b32: \(base32Encode(chksm))")
        print("phonepart b32: \(base32Encode(phonepart))")
        //let phone_part_b32 = base32Encode(phonepart)
        chksm.append(contentsOf: phonepart)

        let chksm_b32 = base32Encode(chksm)
        let split_text = insertPeriodically(text: chksm_b32, insert: " ", period: 4)
        let toshow = split_text.replacingOccurrences(of: "=", with: "")
        print("show to user: \(toshow)")
        
        // 4. Open dialog and show the phonepart to the user
        let alert = UIAlertController(title: "Your part of the secret", message: "\(toshow)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
        
        return t
    }
    
    func insertPeriodically(text:String, insert:String, period:Int) -> String {
        var count = 0
        var res:String = ""
        for char in text {
            if(count == period){
                res.append(insert)
                res.append(char)
                count = 1
                continue
            }
            res.append(char)
            count += 1
        }
        return res
    }
}

// MARK: - TableView Delegate
extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("You tapped cell number \(indexPath.row).")
    }

    // number of elements in the data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("tokens count returned: \(tokenlist.count)")
        return tokenlist.count
    }
    
    // called for every (new) item - configure cell here
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell") as! TableViewCell
        //print("cellForRowAt: \(indexPath.row)")

        cell.setupCell(tokenlist[indexPath.row], indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // this is used for iOS versions <11
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //print("EditActionsForRowAt : \(indexPath.row)")
        // 1. Button: Delete
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexpath) in
            // show confirmation dialog
            let confirmationController = UIAlertController(title: "",
                    message: "Do you really want to remove \(self.tokenlist[indexPath.row].label) ?", preferredStyle: .alert)

            // delete the token
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
                self.tokenlist.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.util.saveTokens(list: self.tokenlist)
            }
            //the cancel action doing nothing
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }

            //adding the action to dialogbox
            confirmationController.addAction(confirmAction)
            confirmationController.addAction(cancelAction)

            //finally presenting the dialog box
            self.present(confirmationController, animated: true, completion: nil)
        }
        deleteAction.backgroundColor = .red
        
        // 2. Button: Rename
        let renameAction = UITableViewRowAction(style: .normal, title: "Rename")
        { (action, indexPath) in
            let alertController = UIAlertController(title: "",
                    message: "Rename \(self.tokenlist[indexPath.row].label)", preferredStyle: .alert)

            // change the name, save and reload table after confirming
            let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                 if let name = alertController.textFields?[0].text {
                     if name == "" {
                         let alert = UIAlertController(title: "Empty name", message: "Please enter a new name.",
                                 preferredStyle: UIAlertControllerStyle.alert)
                         alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                         self.present(alert, animated: true, completion: nil)
                         return
                     }
                     self.tokenlist[indexPath.row].label = name
                     self.util.saveTokens(list: self.tokenlist)
                     self.tableView.reloadData()
                 } else { }
            }

            // the cancel action doing nothing
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }

            alertController.addTextField { (textField) in
                textField.placeholder = "Enter new name"
            }

            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        }

        renameAction.backgroundColor = UIColor(red: 0.670465749, green: 0.8777691889, blue: 1, alpha: 1)
        return [deleteAction,renameAction]
    }

    // disable the delete and insert action in edit mode
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        //print("EditingStyleForRowAt : \(indexPath.row)")
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    // move items in list
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //print("move row at: from: \(sourceIndexPath.row) to \(destinationIndexPath.row)")
        let movedObject = self.tokenlist[sourceIndexPath.row]
        self.tokenlist.remove(at: sourceIndexPath.row)
        self.tokenlist.insert(movedObject, at: destinationIndexPath.row)
        util.saveTokens(list: self.tokenlist)
    }
    
    // this is used for iOS versions >= 11
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 1. Button: Delete
        let deleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            // show confirmation dialog
            let confirmationController = UIAlertController(title: "",
                    message: "Do you really want to remove \(self.tokenlist[indexPath.row].label) ?", preferredStyle: .alert)
            
            // delete the token
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
                self.tokenlist.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.util.saveTokens(list: self.tokenlist)
            }
            //the cancel action doing nothing
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
            
            //adding the action to dialogbox
            confirmationController.addAction(confirmAction)
            confirmationController.addAction(cancelAction)
            
            //finally presenting the dialog box
            self.present(confirmationController, animated: true, completion: nil)
            
            success(true)
        })
        deleteAction.backgroundColor = .red
        
        // 2. Button: Rename
        let renameAction = UIContextualAction(style: .normal, title:  "Rename", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            let alertController = UIAlertController(title: "",
                    message: "Rename \(self.tokenlist[indexPath.row].label)", preferredStyle: .alert)
            
            // change the name, save and reload table after confirming
            let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                if let name = alertController.textFields?[0].text {
                    if name == "" {
                        let alert = UIAlertController(title: "Empty name", message: "Please enter a new name.",
                                                      preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.tokenlist[indexPath.row].label = name
                    self.util.saveTokens(list: self.tokenlist)
                    self.tableView.reloadData()
                } else { }
            }
            // the cancel action doing nothing
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
            
            alertController.addTextField { (textField) in textField.placeholder = "Enter new name" }
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            success(true)
        })
        renameAction.backgroundColor = UIColor(red: 0.670465749, green: 0.8777691889, blue: 1, alpha: 1)
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction,renameAction])
        return config
    }
}

// MARK: - QRScanResult Delegate
extension TableViewController: QRScanResultDelegate {
    func passScanResult(code: String) {
        // create a token from the scan result and add it to the list
        //print("scanned: \(code)")
        var type: String = "hotp"
        var digits: Int = 6
        var algorithm: String = "sha1"
        var secret: Data = base32DecodeToData("ABCDEFGHIJKLMNOP")!
        var label: String = "Issuer:ID"
        var counter: Int = 1
        var period: Int? = nil

        var two_step_init = false
        var two_step_salt = 10              // default value in bytes, part that is generated by the phone
        var two_step_difficulty = 10000     // default value pbkdf2 iterations
        var two_step_output = 160           // default value output size of pbkdf in BIT

        if let comp = URLComponents(string: code), let queryItems = comp.queryItems {

            if comp.host! == "totp" {
                type = "totp"
            }

            label = comp.path
            label.remove(at: label.startIndex) // remove first /

            for i in 0..<queryItems.count {
                // Usual elements of the key URI format
                if queryItems[i].name == "secret" {
                    guard let tmp = queryItems[i].value else {
                        print("failed for " + queryItems[i].name)
                        continue
                    }
                    secret = base32DecodeToData(tmp)!
                }
                if queryItems[i].name == "issuer" {
                    guard let tmp = queryItems[i].value else {
                        print("failed for " + queryItems[i].name)
                        continue
                    }
                    let full_label = tmp + ":" + label
                    label = full_label
                }
                if queryItems[i].name == "digits" {
                    guard let tmp = queryItems[i].value else {
                        print("failed for " + queryItems[i].name)
                        continue
                    }
                    digits = Int(tmp)!
                }
                if queryItems[i].name == "period" {
                    guard let tmp = queryItems[i].value else {
                        print("failed for " + queryItems[i].name)

                        continue
                    }
                    period = Int(tmp)
                }
                if queryItems[i].name == "counter" {
                    guard let tmp = queryItems[i].value else {
                        counter = 1
                        print("failed for " + queryItems[i].name)
                        continue
                    }
                    counter = Int(tmp)!
                }
                if queryItems[i].name == "algorithm" {
                    guard let tmp = queryItems[i].value else {
                        // use default on error / missing
                        continue
                    }
                    algorithm = tmp
                }

                ///////////////////////////////////////////////
                // Additional elements for possible 2step init
                ///////////////////////////////////////////////

                // if at least one parameter is set, we start 2step init
                if queryItems[i].name == "2step_salt" {
                    two_step_init = true
                    guard let tmp = queryItems[i].value else {
                        continue
                    }
                    two_step_salt = Int(tmp)!
                    print("2step salt: \(two_step_salt)")
                }

                if queryItems[i].name == "2step_output" {
                    two_step_init = true
                    guard let tmp = queryItems[i].value else {
                        // if there is no value, we derive it from the tokens algorithm
                        if algorithm == "sha1" {
                        } // is already default
                        if algorithm == "sha256" {
                            two_step_output = 256
                        }
                        if algorithm == "sha512" {
                            two_step_output = 512
                        }
                        continue
                    }
                    two_step_output = Int(tmp)! * 8     // comes in byte, we need bit
                    print("2step output: \(two_step_output)")
                }

                if queryItems[i].name == "2step_difficulty" {
                    two_step_init = true
                    guard let tmp = queryItems[i].value else {
                        continue
                    }
                    two_step_difficulty = Int(tmp)!
                    print("2step diff: \(two_step_difficulty)")
                }
            }
        }

        let t = Token(type: type, digits: digits, algorithm: algorithm, secret: secret, label: label, counter: counter, period: period)
        
        if two_step_init {
            DispatchQueue.global(qos: .background).async { // sends registration to background queue
                print("starting 2step")
                let t2 = self.do2stepinit(t: t, salt_size: two_step_salt, difficulty: two_step_difficulty, output: two_step_output)
                
                self.tokenlist.append(t2)
                self.util.saveTokens(list: self.tokenlist)
                self.tableView.reloadData()
            }
        } else {
        tokenlist.append(t)
        util.saveTokens(list: tokenlist)
        tableView.reloadData()
        }
    }
}

// MARK: COLOR EXTENSION FOR RGBA
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
}
