//
//  StartReadPassportController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit

class StartReadPassportController:UIViewController,PassportControllerDelegate {
    
    
    var passportModel:PassportModel?
    var passport:PassportController?
    var mrz:String?
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.progress = 0.0
        //mrz = "AA1078870773063091803138"
        passport?.ReadRFIDData(mrz: mrz!, dg1: true, dg2: true, dg11: true)
        passport?.delegate = self
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func onProgressReadPassportData(progress: Float) {
        DispatchQueue.main.async {
            self.progressBar.setProgress(progress, animated: true)
        }
        
    }
    
    func onCompleteReadPassportData(data: PassportModel) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showPassportData", sender: nil)
        }
    }
    
    func onBeginCardSession(isSuccess: Bool) {
        if !isSuccess {
            let overlay = AlertPopUpViewController(message: "No Smart Card Found")
            overlay.appear(sender: self)
        }
    }
    
    func onErrorOccur(errorMessage: String, isError: Bool) {
        if isError {
            let overlay = AlertPopUpViewController(message: errorMessage)
            overlay.appear(sender: self)
        }
    }
    
    @IBAction func pressRead(_ sender: UIButton) {
        passport?.ReadRFIDData(mrz: mrz!, dg1: true, dg2: true, dg11: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPassportData" {
            let controller = segue.destination as! PassportDataViewController
            controller.passport = passport
        }
    }
    
}
