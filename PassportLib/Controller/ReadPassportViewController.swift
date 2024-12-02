//
//  ReadPassportViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit
import Vision

class ReadPassportViewController:UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    var readerManager:ReaderController?
    var passport:PassportController?
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        readerManager = ReaderController()
        textField.text = ""
        recognizeText()
    }
    
    
    @IBAction func pressReadPassport(_ sender: UIButton) {
        Task { @MainActor in
            let isSmartCardInit = await readerManager?.initSmartCard()
            if isSmartCardInit! {
                if textField.text!.count < 10 {
                    
                }else{
                    passport = PassportController(rmngr: readerManager!,isSmartCardInitialized:isSmartCardInit!)
                    performSegue(withIdentifier: "startReadPassport", sender: nil)
                }
            }else{
                let overlay = ErrorPopUpViewController()
                overlay.appear(sender: self)
            }
        }
    }
    
    
    @IBAction func pressReTake(_ sender: UIButton) {
        performSegue(withIdentifier: "takePassport", sender: self)
    }
    
    private func recognizeText(){
        let image = image
        
        guard let cgImage = image?.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            guard let result = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            let recogArr = result.compactMap { result in
                result.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                print(recogArr)
                if recogArr.count > 1 {
                    let documentnum = recogArr[1].prefix(10)
                    let birthDate = recogArr[1].dropFirst(13).prefix(7)
                    let expireDate = recogArr[1].dropFirst(21).prefix(7)
                    self.textField.text = "\(documentnum)\(birthDate)\(expireDate)"
                    print(recogArr[1])
                }else if recogArr.count > 2 {
                    let documentnum = recogArr[2].prefix(10)
                    let birthDate = recogArr[2].dropFirst(13).prefix(7)
                    let expireDate = recogArr[2].dropFirst(21).prefix(7)
                    self.textField.text = "\(documentnum)\(birthDate)\(expireDate)"
                    print(recogArr[2])
                }
                else{
                    self.textField.text = "Error can't ocr mrz !!!"
                }
                
            }
            
        }
        
        request.recognitionLevel = .accurate
        
        do{
            try handler.perform([request])
        }catch{
            print(error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startReadPassport" {
            let controller = segue.destination as! StartReadPassportController
            controller.passport = passport
            controller.mrz = textField.text
        }
    }
}
