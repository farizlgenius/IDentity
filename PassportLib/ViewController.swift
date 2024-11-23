//
//  ViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 8/11/2567 BE.
//

import UIKit

class ViewController: UIViewController {
    
    var lib:PassportLibController?
    
    @IBOutlet weak var showImage: UIImageView!
    @IBOutlet weak var textArea: UITextView!
    @IBOutlet weak var mrzData: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lib = PassportLibController()
    }

    @IBAction func startPress(_ sender: UIButton) {
        
        var mrz:String = mrzData.text!
        mrz = "AC6739780296091633405064"
        //"AA1078870773063091803138"
        //"K760625<<273063091210244"
        //"AA9689232973063092301309"
        //"AC6739780296091633405064"
        lib?.ReadRFIDData(mrz:mrz,dg1: false,dg2: false,dg3: false,dg11: true)

    }
    
    @IBAction func pressShowData(_ sender: Any) {
        textArea.text = lib?.model?.DG1
        let data = UIImage(data:(lib?.model?.DG2)!)!.jpegData(compressionQuality: 1.0)
        showImage.image = UIImage(data: data!)
    }
}

