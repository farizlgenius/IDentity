//
//  StartReadThaiIdViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 27/11/2567 BE.
//

import Foundation
import UIKit

class StartReadThaiIdViewController:UIViewController,ThaiIdControllerDelegate {
    
    
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    var thaiIdModel:ThaiIdModel?
    var thai:ThaiIdController?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        progressBar.progress = 0.0
        thai?.delegate = self
        thai?.readThaiID(isImageRequire: true)
        
    }
    
    func onProgressReadThaiIdData(progress: Float) {
        DispatchQueue.main.async {
            self.progressBar.setProgress(progress, animated: true)
        }
    }
    
    func onCompleteReadThaiIdData(data: ThaiIdModel) {
        DispatchQueue.main.async {
            self.thaiIdModel = data
            self.performSegue(withIdentifier: "showThaiIdData", sender: nil)
        }
    }
    
    func onBeginCardSession(isSuccess: Bool) {
        if !isSuccess {
            let overlay = NotFoundReaderPopUpViewController()
            overlay.appear(sender: self)
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showThaiIdData" {
            let controller = segue.destination as! PassportDataViewController
            controller.thaiIdModel = thaiIdModel
        }
    }
}
