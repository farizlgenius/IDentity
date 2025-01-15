//
//  PassportDataViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import Foundation
import UIKit
import PassportNFCProfessional

class PassportDataViewController:UIViewController {
    
    //var passport:PassportController?
    var model:PassportModel?
    var data:[String] = []
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        tableView.delegate = self
        tableView.dataSource = self
        if model != nil {
            title = "Passport"
            data.append("Document Code : \(model?.documentCode ?? "")")
            data.append("Document Number : \(model?.documentNumber ?? "")")
            data.append("Title : \(model?.title ?? "")")
            data.append("First Name : \(model?.holderFirstName ?? "")")
            data.append("Middle Name : \(model?.holderMiddleName ?? "")")
            data.append("Last Name : \(model?.holderLastName ?? "")")
            data.append("Date of Birth : \(model?.dateOfBirth ?? "")")
            data.append("Date of Expiry : \(model?.dateOfExpiry ?? "")")
            data.append("Nationality : \(model?.nationality ?? "")")
            data.append("Sex : \(model?.sex == "M" ? "Male" : "Female")")
            data.append("Issue State : \(model?.issueState ?? "")")
            data.append("Personal Number : \(model?.personalNumber ?? "")")
            data.append("Full Date of Birth : \(model?.fullDateOfBirth ?? "")")
            data.append("Place of Birth : \(model?.placeOfBirth ?? "")")
            data.append("Address : \(model?.permanentAddress ?? "")")
            data.append("Telephone : \(model?.telephone ?? "")")
            data.append("Profession : \(model?.profession ?? "")")
            data.append("Personal Summary : \(model?.personelSummary ?? "")")
            
            if model?.faceImage != "" && model?.faceImage != nil {
                let img = Data(base64Encoded: (model?.faceImage)!, options: .ignoreUnknownCharacters)
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
