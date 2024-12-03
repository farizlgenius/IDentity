//
//  PassportDataViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit

class PassportDataViewController:UIViewController {
    
    var passportModel:PassportModel?
    var thaiIdModel:ThaiIdModel?
    var data:[String] = []
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        tableView.delegate = self
        tableView.dataSource = self
        if passportModel != nil {
            title = "Passport"
            data.append("Document Code : \(passportModel?.documentCode ?? "")")
            data.append("Document Number : \(passportModel?.documentNumber ?? "")")
            data.append("First Name : \(passportModel?.holderFirstName ?? "")")
            data.append("Middle Name : \(passportModel?.holderMiddleName ?? "")")
            data.append("Last Name : \(passportModel?.holderLastName ?? "")")
            data.append("Date of Birth : \(passportModel?.dateOfBirth ?? "")")
            data.append("Date of Expiry : \(passportModel?.dateOfExpiry ?? "")")
            data.append("Nationality : \(passportModel?.nationality ?? "")")
            data.append("Sex : \(passportModel?.sex == "M" ? "Male" : "Female")")
            data.append("Issue State : \(passportModel?.issueState ?? "")")
            if passportModel?.faceImage != "" && passportModel?.faceImage != nil {
                let img = Data(base64Encoded: (passportModel?.faceImage)!, options: .ignoreUnknownCharacters)
                imageView.image = UIImage(data: img!)
            }
        }
        
        if thaiIdModel != nil {
            title = "Thai ID"
            data.append("Card Type : \(thaiIdModel?.cardType ?? "")")
            data.append("Card ID : \(thaiIdModel?.cId ?? "")")
            data.append("thFullName : \(thaiIdModel?.thaiFullName ?? "")")
            data.append("thTitleName : \(thaiIdModel?.thaiTitleName ?? "")")
            data.append("thMiddleName : \(thaiIdModel?.thaiMiddleName ?? "")")
            data.append("thLastName : \(thaiIdModel?.thaiLastName ?? "")")
            data.append("enFullName : \(thaiIdModel?.engFullName ?? "")")
            data.append("enTitleName : \(thaiIdModel?.engTitleName ?? "")")
            data.append("enMiddleName : \(thaiIdModel?.engMiddleName ?? "")")
            data.append("enLastName : \(thaiIdModel?.engLastName ?? "")")
            data.append("Gender : \(thaiIdModel?.gender == "1" ? "Male" : "Female")")
            data.append("Birth Date : \(thaiIdModel?.dateOfBirth ?? "")")
            data.append("Expire Date : \(thaiIdModel?.expireDate ?? "")")
            data.append("Chip ID : \(thaiIdModel?.chipId ?? "")")
            data.append("bp1No : \(thaiIdModel?.bp1no ?? "")")
            data.append("Laser ID : \(thaiIdModel?.laserId ?? "")")
            data.append("Issuer Code : \(thaiIdModel?.issuerCode ?? "")")
            data.append("Card Issuer : \(thaiIdModel?.cardIssuer ?? "")")
            data.append("Issue Date : \(thaiIdModel?.issueDate ?? "")")
            data.append("Address : \(thaiIdModel?.address ?? "")")
            data.append("Moo : \(thaiIdModel?.moo ?? "")")
            data.append("Trok : \(thaiIdModel?.trok ?? "")")
            data.append("Soi : \(thaiIdModel?.soi ?? "")")
            data.append("Thanon : \(thaiIdModel?.thanon ?? "")")
            data.append("Tumbol : \(thaiIdModel?.tumbol ?? "")")
            data.append("Amphur : \(thaiIdModel?.amphur ?? "")")
            data.append("Province : \(thaiIdModel?.provice ?? "")")
            data.append("Phot Ref No. : \(thaiIdModel?.photoRefNumber ?? "")")
            if thaiIdModel?.base64Img != "" {
                let img = Data(base64Encoded: (thaiIdModel?.base64Img)!, options: .ignoreUnknownCharacters)
                imageView.image = UIImage(data: img!)
            }
            
        }
        
        

    }
    
    
    @IBAction func restartPressed(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
}

extension PassportDataViewController : UITableViewDelegate {
    
    func tableView(_ tableView:UITableView,didSelectRowAt indexPath:IndexPath){
        print("you tapped me!")
    }
}

extension PassportDataViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
}
