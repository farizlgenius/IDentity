//
//  StartReadPassportController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit
import PassportNFCProfessional
import QKMRZScanner

class StartReadPassportController:UIViewController,PassportControllerDelegate {
    
    
    var model:PassportModel?
    var passport:PassportController?
    var ocrResult:QKMRZScanResult?
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.progress = 0.0
        print(ocrResult?.documentNumber)
        print(dateToString((ocrResult?.birthdate)!))
        print(dateToString((ocrResult?.expiryDate)!))
        passport?.ReadRFIDData(documentNo:ocrResult!.documentNumber, dob: dateToString((ocrResult?.birthdate)!), doe: dateToString((ocrResult?.expiryDate)!),dg1: true,dg2: true,dg11: true)
        passport?.delegate = self
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func dateToString(_ date:Date)->String{
        let formatter = DateFormatter()
        formatter.dateFormat = "YYMMdd"
        return formatter.string(from: date)
    }
    
    func onProgressReadPassportData(progress: Float) {
        DispatchQueue.main.async {
            self.progressBar.setProgress(progress, animated: true)
        }
        
    }
    
    func onCompleteReadPassportData(data: PassportModel) {
        DispatchQueue.main.async {
            self.model = data
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
            DispatchQueue.main.async {
                let overlay = AlertPopUpViewController(message: errorMessage)
                overlay.appear(sender: self)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPassportData" {
            let controller = segue.destination as! PassportDataViewController
            controller.model = model
        }
    }
    
}
