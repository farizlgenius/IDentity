//
//  StartReadThaiIdViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 27/11/2567 BE.
//

import Foundation
import UIKit

class StartReadThaiIdViewController:UIViewController {
    
    var thai:ThaiIdController?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        thai?.readThaiID(isImageRequire: false)
        
    }
}
