//
//  ViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 8/11/2567 BE.
//

import UIKit

class ViewController: UIViewController {
    
    var lib:PassportController?
    var reader:ReaderController?
    
    @IBOutlet weak var showImage: UIImageView!
    @IBOutlet weak var textArea: UITextView!
    @IBOutlet weak var mrzData: UITextField!
    
    @IBOutlet weak var documentCodeLabel: UILabel!
    
    @IBOutlet weak var issueStateLabel: UILabel!
    
    @IBOutlet weak var holderFirstNameLabel: UILabel!
    
    @IBOutlet weak var holderMiddleNameLabel: UILabel!
    
    @IBOutlet weak var holderLastNameLabel: UILabel!
    
    @IBOutlet weak var documentNumberLabel: UILabel!
    
    @IBOutlet weak var nationalityLabel: UILabel!
    
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    
    @IBOutlet weak var sexLabel: UILabel!
    
    @IBOutlet weak var dateOfExpireLabel: UILabel!
    
    @IBOutlet weak var optionalDataLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        reader = ReaderController()
        lib = PassportController(rmngr: reader!)
    }

    @IBAction func startPress(_ sender: UIButton) {
        
        var mrz:String = mrzData.text!
        mrz = "AA9689232973063092301309"
        //"AA1078870773063091803138"
        //"K760625<<273063091210244"
        //"AA9689232973063092301309"
        //"AC6739780296091633405064"
        lib?.ReadRFIDData(mrz:mrz,dg1: true,dg2: true,dg3: false,dg11: false)

    }
    
    @IBAction func pressShowData(_ sender: Any) {
        textArea.text = lib?.model?.DG1
        let data = UIImage(data:(lib?.model?.DG2)!)!.jpegData(compressionQuality: 1.0)
        showImage.image = UIImage(data: data!)
        documentCodeLabel.text = lib?.model?.documentCode
        issueStateLabel.text = lib?.model?.issueState
        holderFirstNameLabel.text = lib?.model?.holderFirstName
        holderMiddleNameLabel.text = lib?.model?.holderMiddleName
        holderLastNameLabel.text = lib?.model?.holderLastName
        documentNumberLabel.text = lib?.model?.documentNumber
        nationalityLabel.text = lib?.model?.nationality
        dateOfBirthLabel.text = lib?.model?.dateOfBirth
        sexLabel.text = lib?.model?.sex
        dateOfExpireLabel.text = lib?.model?.dateOfExpiry
        optionalDataLabel.text = lib?.model?.optionalData
        
    }
}

