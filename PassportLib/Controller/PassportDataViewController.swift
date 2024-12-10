//
//  PassportDataViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit

class PassportDataViewController:UIViewController {
    
    var passport:PassportController?
    var thai:ThaiIdController?
    var data:[String] = []
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        tableView.delegate = self
        tableView.dataSource = self
        if passport?.data != nil {
            title = "Passport"
            data.append("Document Code : \(passport?.data?.documentCode ?? "")")
            data.append("Document Number : \(passport?.data?.documentNumber ?? "")")
            data.append("Title : \(passport?.data?.title ?? "")")
            data.append("First Name : \(passport?.data?.holderFirstName ?? "")")
            data.append("Middle Name : \(passport?.data?.holderMiddleName ?? "")")
            data.append("Last Name : \(passport?.data?.holderLastName ?? "")")
            data.append("Date of Birth : \(passport?.data?.dateOfBirth ?? "")")
            data.append("Date of Expiry : \(passport?.data?.dateOfExpiry ?? "")")
            data.append("Nationality : \(passport?.data?.nationality ?? "")")
            data.append("Sex : \(passport?.data?.sex == "M" ? "Male" : "Female")")
            data.append("Issue State : \(passport?.data?.issueState ?? "")")
            data.append("Personal Number : \(passport?.data?.personalNumber ?? "")")
            data.append("Full Date of Birth : \(passport?.data?.fullDateOfBirth ?? "")")
            data.append("Place of Birth : \(passport?.data?.placeOfBirth ?? "")")
            data.append("Address : \(passport?.data?.permanentAddress ?? "")")
            data.append("Telephone : \(passport?.data?.telephone ?? "")")
            data.append("Profession : \(passport?.data?.profession ?? "")")
            data.append("Personal Summary : \(passport?.data?.personelSummary ?? "")")
            
            if passport?.data?.faceImage != "" && passport?.data?.faceImage != nil {
                let img = Data(base64Encoded: (passport?.data?.faceImage)!, options: .ignoreUnknownCharacters)
                imageView.image = UIImage(data: img!)
            }
        }
        
        if thai != nil {
            title = "Thai ID"
            data.append("Card Type : \(thai?.data?.cardType ?? "")")
            data.append("Card ID : \(thai?.data?.cId ?? "")")
            data.append("thFullName : \(thai?.data?.thaiFullName ?? "")")
            data.append("thTitleName : \(thai?.data?.thaiTitleName ?? "")")
            data.append("thMiddleName : \(thai?.data?.thaiMiddleName ?? "")")
            data.append("thLastName : \(thai?.data?.thaiLastName ?? "")")
            data.append("enFullName : \(thai?.data?.engFullName ?? "")")
            data.append("enTitleName : \(thai?.data?.engTitleName ?? "")")
            data.append("enMiddleName : \(thai?.data?.engMiddleName ?? "")")
            data.append("enLastName : \(thai?.data?.engLastName ?? "")")
            data.append("Gender : \(thai?.data?.gender == "1" ? "Male" : "Female")")
            data.append("Birth Date : \(thai?.data?.dateOfBirth ?? "")")
            data.append("Expire Date : \(thai?.data?.expireDate ?? "")")
            data.append("Chip ID : \(thai?.data?.chipId ?? "")")
            data.append("bp1No : \(thai?.data?.bp1no ?? "")")
            data.append("Laser ID : \(thai?.data?.laserId ?? "")")
            data.append("Issuer Code : \(thai?.data?.issuerCode ?? "")")
            data.append("Card Issuer : \(thai?.data?.cardIssuer ?? "")")
            data.append("Issue Date : \(thai?.data?.issueDate ?? "")")
            data.append("Address : \(thai?.data?.address ?? "")")
            data.append("Moo : \(thai?.data?.moo ?? "")")
            data.append("Trok : \(thai?.data?.trok ?? "")")
            data.append("Soi : \(thai?.data?.soi ?? "")")
            data.append("Thanon : \(thai?.data?.thanon ?? "")")
            data.append("Tumbol : \(thai?.data?.tumbol ?? "")")
            data.append("Amphur : \(thai?.data?.amphur ?? "")")
            data.append("Province : \(thai?.data?.provice ?? "")")
            data.append("Phot Ref No. : \(thai?.data?.photoRefNumber ?? "")")
            if thai?.data?.base64Img != "" && thai?.data?.base64Img != nil {
                let img = Data(base64Encoded: (thai?.data?.base64Img)!, options: .ignoreUnknownCharacters)
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
