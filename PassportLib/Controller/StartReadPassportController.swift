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
        passport?.ReadRFIDData(mrz: mrz!, dg1: true, dg2: true, dg3: false, dg7:false, dg11: false, dg12: false, dg15: false)
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
            self.passportModel = data
            self.performSegue(withIdentifier: "showPassportData", sender: nil)
        }
    }
    
    func onBeginCardSession(isSuccess: Bool) {
        if !isSuccess {
            let overlay = ErrorPopUpViewController()
            overlay.appear(sender: self)
        }
    }
    
    @IBAction func pressRead(_ sender: UIButton) {
        passport?.ReadRFIDData(mrz: mrz!, dg1: true, dg2: true, dg3: false, dg7:false, dg11: false, dg12: false, dg15: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPassportData" {
            let controller = segue.destination as! PassportDataViewController
            controller.passportModel = passportModel
        }
    }
    
}
