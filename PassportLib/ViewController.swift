//
//  ViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 8/11/2567 BE.
//

import UIKit

class ViewController: UIViewController {
    
    var lib:PassportLib?
    
    @IBOutlet weak var textArea: UITextView!
    @IBOutlet weak var inputField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lib = PassportLib()
    }

    @IBAction func startPress(_ sender: UIButton) {
        
        lib?.startReadDGData(mrz:"AA9689232973063092301309")
//        "AA9689232973063092301309"
//        "AA1078844274061171803138"
        
    }
    
}

