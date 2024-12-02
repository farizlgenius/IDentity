//
//  ReadThaiIdViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 27/11/2567 BE.
//

import Foundation
import UIKit

class ReadThaiIdViewController:UIViewController {
    
    var readerManager:ReaderController?
    var thai:ThaiIdController?
    override func viewDidLoad(){
        super.viewDidLoad()
        
        readerManager = ReaderController()
    }
    
    @IBAction func pressReadThaiId(_ sender: Any) {
        Task{ @MainActor in
            let isSmartCardInit = await readerManager?.initSmartCard()
            if isSmartCardInit! {
                thai = ThaiIdController(rmngr: readerManager!,isSmartCardInitialized: isSmartCardInit!)
                performSegue(withIdentifier: "startReadThaiId", sender: nil)
            }else{
                let overlay = ErrorPopUpViewController()
                overlay.appear(sender: self)
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startReadThaiId" {
            let controller = segue.destination as! StartReadThaiIdViewController
            controller.thai = thai
        }
    }
    
}
