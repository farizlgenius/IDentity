//
//  ViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 8/11/2567 BE.
//

import UIKit

class ViewController: UIViewController {
    
    var lib:PassportLib?
    
    @IBOutlet weak var showImage: UIImageView!
    @IBOutlet weak var textArea: UITextView!
    @IBOutlet weak var mrzData: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lib = PassportLib()
    }

    @IBAction func startPress(_ sender: UIButton) {
        
        let mrz:String = mrzData.text!
        print(mrz)
        lib?.startReadDGData(mrz:mrz)

    }
    
    @IBAction func pressShowData(_ sender: Any) {
        textArea.text = lib?.model?.DG1
        let data = UIImage(data:(lib?.model?.DG2)!)!.jpegData(compressionQuality: 1.0)
        showImage.image = UIImage(data: data!)
    }
}

