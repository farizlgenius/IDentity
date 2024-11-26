//
//  ReadPassportViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit

class ReadPassportViewController:UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    var readerManager:ReaderController?
    var passport:PassportController?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        readerManager = ReaderController()
    }
    
    @IBAction func pressReadPassport(_ sender: UIButton) {
        Task { @MainActor in
            let isSmartCardInit = await readerManager?.initSmartCard()
            if isSmartCardInit! {
                if textField.text!.count < 10 {
                    
                }else{
                    passport = PassportController(rmngr: readerManager!)
                    performSegue(withIdentifier: "startReadPassport", sender: nil)
                }
            }else{
                let overlay = NotFoundReaderPopUpViewController()
                overlay.appear(sender: self)
            }
        }
    }
    
    @IBAction func pressRestart(_ sender: UIButton) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startReadPassport" {
            let controller = segue.destination as! StartReadPassportController
            controller.passport = passport
            controller.mrz = textField.text
        }
    }
}
