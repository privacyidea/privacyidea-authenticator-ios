//
//  TableViewController.swift
//  test
//
//  Created by Nils Behlen on 08.08.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import UIKit
import Toast_Swift

class TableViewController: UIViewController {
    
    // MARK: Variables
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var tableViewLeadingC: NSLayoutConstraint!
    @IBOutlet weak var tableViewTrailingC: NSLayoutConstraint!
    
    private var timer: Timer?
    private var presenterDelegate: PresenterDelegate?
    private var presenter: Presenter?
    private var menuOpen: Bool = false
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var addManuallyBtn: UIButton!
    @IBOutlet weak var thirdPartyBtn: UIButton!
    @IBOutlet weak var sortBtn: UIButton!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "privacyIDEA Authenticator"
        
        //////////////////////// ASSEMBLE ////////////////////////
        presenter = Presenter(tokenlistDelegate: self)
        let del = UIApplication.shared.delegate as! AppDelegate
        del.presenterDelegate = presenter
        self.presenterDelegate = presenter
        presenter?.startup()
        
        runTimer()
        
        //////////////////////// SIDE MENU SETUP ////////////////////////
        /*menuView.isHidden = true
         let menuTap = UITapGestureRecognizer(target: self, action: #selector(TableViewController.menuTapped))
         menuView.addGestureRecognizer(menuTap)*/
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(TableViewController.menuTapped))
        leftSwipe.direction = .left
        menuView.addGestureRecognizer(leftSwipe)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
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
            scanQRVC.qrScanDelegate = presenter
        }
        
        if segue.identifier == "ManualAddStart" {
            let manualAddVC = segue.destination as! EnterDetailController
            manualAddVC.presenterDelegate = self.presenterDelegate
        }
    }
    
    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "Version \(version) build \(build)"
    }
    
    @objc func addTapped() {
        let scanQRVC = self.storyboard?.instantiateViewController(withIdentifier: "ScannerViewController") as! ScannerViewController
        scanQRVC.qrScanDelegate = presenter
        navigationController?.pushViewController(scanQRVC, animated: true)
    }
    
    @objc func menuTapped() {
        menuOpen = !menuOpen
        
        if !menuOpen{
            UIView.animate(withDuration: 0.3/*Animation Duration second*/, animations: {
                self.menuView.alpha = 0
            }, completion:  {
                (value: Bool) in
                self.menuView.isHidden = true
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.menuView.alpha = 1
            }, completion:  {
                (value: Bool) in
                self.menuView.isHidden = false
            })
        }
        
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
    }
    
    /**
     Start the timer in a background thread to update the progressbars
     and initiate the update of TOTP tokens
     */
    func runTimer() {
        var seconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t) in
            seconds += 1
            if seconds > 60 {seconds = 1}
            //U.log(seconds)
            self.presenterDelegate?.timerProgress(seconds: seconds)
        }
    }
    
    @IBAction func addManuallyTapped(_ sender: Any) {
        menuTapped() // close the menu
        let aMVC = self.storyboard?.instantiateViewController(withIdentifier: "EnterDetailVC") as! EnterDetailController
        aMVC.presenterDelegate = self.presenterDelegate
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
}

// MARK: - Protocol Implementation
extension TableViewController: TokenlistDelegate {
    func showToastMessage(text: String) {
        DispatchQueue.main.async {
            self.tableView.makeToast(text, duration: Constants.TOAST_UPTIME_IN_S, position: .center, title: nil, image: nil, style: ToastStyle(), completion: nil)
        }
    }
    
    func showMessageWithOKButton(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func reloadCells() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func updateProgressbar(indexPath: IndexPath, progress: Int) {
        let cell = self.tableView.cellForRow(at: indexPath)
        if cell != nil {
            let cell2:TableViewCell = cell as! TableViewCell
            cell2.updateProgressbar(t: (presenterDelegate?.getTokenForRow(index: indexPath.row))!, time: progress)
        }
    }
}

// MARK: - TableView Delegate
extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //U.log("You tapped cell number \(indexPath.row).")
    }
       
    // number of elements in the data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //U.log("tokens count returned: \(tokenlist.count)")
        return self.presenterDelegate?.getListCount() ?? 0
    }
    
    // called for every (new) item - configure cell here
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell") as! TableViewCell
        //U.log("cellForRowAt: \(indexPath.row)")
        cell.setupCell((self.presenterDelegate?.getTokenForRow(index: indexPath.row))!, indexPath.row)
        cell.presenter = self.presenter
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // this is used for iOS versions <11
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //U.log("EditActionsForRowAt : \(indexPath.row)")
        let label: String = self.presenterDelegate?.getTokenForRow(index: indexPath.row).label ?? ""
        
        // 1. Button: Delete
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexpath) in
            // show confirmation dialog
            
            let confirmationController = UIAlertController(title: "",
                                                           message: "Do you really want to remove \(label) ?"
                , preferredStyle: .alert)
            
            // delete the token
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
                self.presenterDelegate?.removeTokenAt(index: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
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
                                                    message: "Rename \(label)"
                , preferredStyle: .alert)
            // change the name, save and reload table after confirming
            let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                if let name = alertController.textFields?[0].text {
                    if name == "" {
                        let alert = UIAlertController(title: "Empty name", message: "Please enter a new name.",
                                                      preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.presenterDelegate?.changeTokenLabel(name, index: indexPath.row)
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
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        //U.log("EditingStyleForRowAt : \(indexPath.row)")
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    // move items in list
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        U.log("move row at: from: \(sourceIndexPath.row) to \(destinationIndexPath.row)")
        self.presenterDelegate?.switchTokenPositions(src_index: sourceIndexPath.row, dest_index: destinationIndexPath.row)
        self.tableView.reloadData()
    }
    
    // this is used for iOS versions >= 11
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let label: String = self.presenterDelegate?.getTokenForRow(index: indexPath.row).label ?? ""
        
        // 1. Button: Delete
        let deleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            // show confirmation dialog
            let confirmationController = UIAlertController(title: "",
                                                           message: "Do you really want to remove \(label)"
                , preferredStyle: .alert)
            // delete the token
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
                self.presenterDelegate?.removeTokenAt(index: indexPath.row)
            }
            //the cancel action doing nothing
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
            
            //adding the action to dialogbox
            confirmationController.addAction(confirmAction)
            confirmationController.addAction(cancelAction)
            
            self.present(confirmationController, animated: true, completion: nil)
            
            success(true)
        })
        deleteAction.backgroundColor = .red
        
        // 2. Button: Rename
        let renameAction = UIContextualAction(style: .normal, title:  "Rename", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            let alertController = UIAlertController(title: "",
                                                    message: "Rename \(label)"
                , preferredStyle: .alert)
            
            // change the name, save and reload table after confirming
            let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                if let name = alertController.textFields?[0].text {
                    if name == "" {
                        let alert = UIAlertController(title: "Empty name", message: "Please enter a new name.",
                                                      preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.presenterDelegate?.changeTokenLabel(name, index: indexPath.row)
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
        //renameAction.backgroundColor = UIColor(red: 0.670465749, green: 0.8777691889, blue: 1, alpha: 1)
        renameAction.backgroundColor = Constants.PI_BLUE
        let config = UISwipeActionsConfiguration(actions: [deleteAction,renameAction])
        return config
    }
}

// MARK: - Color Extension For RGBA
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
