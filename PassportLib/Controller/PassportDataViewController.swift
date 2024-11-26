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
    var data:[String] = []
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
        
        let img = Data(base64Encoded: (passportModel?.faceImage)!, options: .ignoreUnknownCharacters)
        imageView.image = UIImage(data: img!)

    }
    
    @IBAction func pressRestart(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "restart", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "restart" {
            let controller = segue.destination as! MainViewController
        }
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
