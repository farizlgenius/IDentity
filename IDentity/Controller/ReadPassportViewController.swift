//
//  ReadPassportViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit
import PassportNFCProfessional
import QKMRZScanner

class ReadPassportViewController:UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    var readerManager:ReaderController?
    var passport:PassportController?
    var ocrResult:QKMRZScanResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readerManager = ReaderController(isPassport: true)
    }
    
    
    @IBAction func pressReadPassport(_ sender: UIButton) {
        Task { @MainActor in
            let isSmartCardInit = await readerManager?.initSmartCard()
            if isSmartCardInit! {
                passport = PassportController(rmngr: readerManager!,isSmartCardInitialized:isSmartCardInit!)
                performSegue(withIdentifier: "startReadPassport", sender: nil)
            }else{
                let overlay = AlertPopUpViewController(message: "No Reader Found, Please connect reader and try again ")
                overlay.appear(sender: self)
            }
        }
    }
    
   
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startReadPassport" {
            let controller = segue.destination as! StartReadPassportController
            controller.passport = passport
            controller.ocrResult = ocrResult
        }
    }
}
