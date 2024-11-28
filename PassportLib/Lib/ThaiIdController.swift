//
//  ThaiIdController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 25/11/2567 BE.
//

import Foundation
import UIKit

protocol ThaiIdControllerDelegate{
    func onProgressReadThaiIdData(progress:Float)
    func onCompleteReadThaiIdData(data:PassportModel)
    func onBeginCardSession(isSuccess:Bool)
}

class ThaiIdController
{
    // APDU Command
    enum apdu:String {
        case chipId = "80CA9F7F2D"
        case laserId = "00A4040008A000000084060002"
        case getLaserId = "8000000017"
        case readBinary1 = "80B000000200FF"
        case readBinary2 = "80B000FF0200FF"
        case getResponse = "00C00000FF"
        case selectThaiIdDf = "00A4040008A000000054480001"
    }
    
    var apduImg:[String] = ["80B0017B0200FF","80B0027A0200FF","80B003790200FF","80B004780200FF","80B005770200FF","80B006760200FF","80B007750200FF","80B008740200FF","80B009730200FF","80B00A720200FF","80B00B710200FF","80B00C700200FF","80B00D6F0200FF","80B00E6E0200FF","80B00F6D0200FF","80B0106C0200FF","80B0116B0200FF","80B0126A0200FF","80B013690200FF","80B014680200FF"]
    
    // Properties
    let rmngr:ReaderController
    var isSmartCardInitialized:Bool?
    var isCardSessionBegin:Bool?
    let util:Utility?
    var model:ThaiIdModel?
    var progress:Float = 0.0
    var eachProgress:Float = 0.0
    var slotName:String = ""
    
    // Delegate
    var delegate:ThaiIdControllerDelegate?
    
    // Constructor
    init(rmngr:ReaderController,isSmartCardInitialized:Bool){
        util = Utility()
        model = ThaiIdModel()
        self.rmngr = rmngr
        self.isSmartCardInitialized = isSmartCardInitialized
    }
    
    func readThaiID(isImageRequire:Bool) {
        
        // MARK: - Step 1 : Initial SmartCard
        Task.init{
            
            if isSmartCardInitialized! {
                isCardSessionBegin = await rmngr.beginCardSession()
            }
            
            if isCardSessionBegin ?? false {
                
                print("""
                
                #####################################
                            GET CHIP ID 
                #####################################
                
                """)
                
                // MARK: - Step 2 : Send APDU for Get Chip ID
                print("LIB >>>> (APDU CMD GET CHIP ID) >>>> : " + apdu.chipId.rawValue)
                var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.chipId.rawValue)
                print("LIB <<<< (APDU RES GET CHIP ID) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" {
                    model?.chipId = String(res.uppercased().dropFirst(26).dropLast(52))
                    delegate?.onProgressReadThaiIdData(progress: 1)
                }else{
                    print("LIB >>>> GET CHIP ID ERROR ")
                }
                print("LIB >>>> Chip ID : " + (model?.chipId)!)
                
                
                print("""
                
                #####################################
                            GET LASER ID
                #####################################
                
                """)
                
                // MARK: - Step 3 : Send APDU for Select Laser ID
                print("LIB >>>> (APDU CMD SELECT LASER ID) >>>> : " + apdu.laserId.rawValue)
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.laserId.rawValue)
                print("LIB <<<< (APDU RES SELECT LASER ID) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                    
                    // MARK: - Step 4 : Send APDU for get Laser ID
                    print("LIB >>>> (APDU CMD GET LASER ID) >>>> : " + apdu.getLaserId.rawValue)
                    res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getLaserId.rawValue)
                    print("LIB <<<< (APDU RES GET LASER ID) <<<< : " + res.uppercased())
                    let filter = res.dropFirst(14).dropLast(12)
                    print("LIB >>>> Laser ID :  " + util!.hexStringtoAscii(String(filter)))
                    if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                        model?.laserId = util!.hexStringtoAscii(String(filter))
                        delegate?.onProgressReadThaiIdData(progress: 1)
                    }else{
                        print("LIB >>>> GET LASER ID ERROR ")
                    } // End of get laser id

                }else{
                    print("LIB >>>> SELECT LASER ID ERROR ")
                } // End of select laser id
                
                print("""
                
                #####################################
                          GET THAI ID DATA 
                #####################################
                
                """)
                
                // MARK: - Step 4 : Send APDU for Select Thai ID Card Data
                print("LIB >>>> (APDU CMD SELECT THAI ID) >>>> : " + apdu.selectThaiIdDf.rawValue)
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.selectThaiIdDf.rawValue)
                print("LIB <<<< (APDU RES SELECT THAI ID) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                    
                    // MARK: - Step 4 : Send APDU for get Laser ID
                    print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apdu.readBinary1.rawValue)
                    res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.readBinary1.rawValue)
                    print("LIB <<<< (APDU RES GET THAI ID DATA) <<<< : " + res.uppercased())
                    if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                        
                        delegate?.onProgressReadThaiIdData(progress: 1)
                        
                        // MARK: - Step 6 : Send APDU for recieve data part 1
                        
                        print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apdu.getResponse.rawValue)
                        res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                        print("LIB <<<< (APDU RES GET THAI ID DATA) <<<< : " + res.uppercased())
                        if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                            
                            // Card Type
                            model?.cardType = util!.hexStringtoAscii(String(res.prefix(8)))
                            print("LIB >>>> Card Type :  " +  (model?.cardType)!)
                            res = String(res.dropFirst(8))
                            
                            // Thai ID
                            model?.cId = util?.hexStringtoAscii(String(res.prefix(26)))
                            print("LIB >>>> Thai ID :  " +  (model?.cId)!)
                            res = String(res.dropFirst(26))
                            
                            // Thai Full Name
                            let thFullName = res.prefix(200)
                            let d = String(thFullName).hexadecimal
                            model?.thaiFullName = util!.hexStringtoAscii(String(thFullName))
                            print("LIB >>>> Thai Full Name :  " +  (model?.thaiFullName)!)
    //                        // Thai Title Name
    //                        //model?.thaiTitleName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai First Name :  " +  (model?.thaiTitleName)!)
    //                        // Thai First Name
    //                        //model?.thaiFirstName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai First Name :  " +  (model?.thaiFirstName)!)
    //                        // Thai Middle Name
    //                        //model?.thaiMiddleName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai Middle Name :  " +  (model?.thaiMiddleName)!)
    //                        // Thai Last Name
    //                        //model?.thaiLastName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai Last Name :  " +  (model?.thaiLastName)!)
                            res = String(res.dropFirst(200))
                            
                            // Eng Full Name
                            let enFullName = res.prefix(200)
                            model?.engFullName = util?.hexStringtoAscii(String(enFullName))
                            print("LIB >>>> Eng Full Name :  " +  (model?.engFullName)!)
                            
                            // Eng Title Name
    //                        //model?.thaiTitleName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai First Name :  " +  (model?.engTitleName)!)
    //                        // Eng First Name
    //                        //model?.thaiFirstName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai First Name :  " +  (model?.engFirstName)!)
    //                        // Eng Middle Name
    //                        //model?.thaiMiddleName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai Middle Name :  " +  (model?.engMiddleName)!)
    //                        // Eng Last Name
    //                        //model?.thaiLastName = util?.hexStringtoAscii()
    //                        print("LIB >>>> Thai Last Name :  " +  (model?.engLastName)!)
                            res = String(res.dropFirst(200))
                            
                            // Birth Date
                            model?.dateOfBirth = util?.hexStringtoAscii(String(res.prefix(16)))
                            print("LIB >>>> Birth Date :  " +  (model?.dateOfBirth)!)
                            res = String(res.dropFirst(16))
                            
                            // Gender
                            model?.gender = util?.hexStringtoAscii(String(res.prefix(2)))
                            print("LIB >>>> Gender :  " +  (model?.gender)!)
                            res = String(res.dropFirst(2))
                            
                            // Bp1no
                            model?.bp1no = util?.hexStringtoAscii(String(res.prefix(40)))
                            print("LIB >>>> BP1No :  " +  (model?.bp1no)!)
                            res = String(res.dropFirst(40))
                            
                            // Card Issuer p1
                            model?.cardIssuer = util?.hexStringtoAscii(String(res.dropLast(4)))
                            
                            
                        }else{
                            print("LIB >>>> GET RES THAI ID ERROR ")
                        } // End of get response Thai id p1
                    }else{
                        print("LIB >>>> READ BINARY THAI ID 1")
                    } // End of Read binary thai id 1
                    
                    // MARK: - Step 7 : Send APDU for read binary data part 2
                    
                    print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apdu.readBinary2.rawValue)
                    res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.readBinary2.rawValue)
                    print("LIB <<<< (APDU RES GET THAI ID DATA) <<<< : " + res.uppercased())
                    if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                        
                        // MARK: - Step 8 : Send APDU for recieve data part 2
                        
                        print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apdu.getResponse.rawValue)
                        res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                        print("LIB <<<< (APDU RES GET THAI ID DATA) <<<< : " + res.uppercased())
                        if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                            
                            // Card Issuer p2
                            model?.cardIssuer! += (util?.hexStringtoAscii(String(res.prefix(182))))!
                            print("LIB >>>> Card Issuer :  " +  (model?.cardIssuer)!)
                            res = String(res.dropFirst(182))
                            
                            // Issuer Code
                            model?.issuerCode = util?.hexStringtoAscii(String(res.prefix(26)))
                            print("LIB >>>> Issuer Code :  " +  (model?.issuerCode)!)
                            res = String(res.dropFirst(26))
                            
                            // Date of Issue
                            model?.issueDate = util?.hexStringtoAscii(String(res.prefix(16)))
                            print("LIB >>>> Issue Date :  " +  (model?.issueDate)!)
                            res = String(res.dropFirst(16))
                            
                            // Expire Date
                            model?.expireDate = util?.hexStringtoAscii(String(res.prefix(16)))
                            print("LIB >>>> Expire Date :  " +  (model?.expireDate)!)
                            res = String(res.dropFirst(16))
                            
                        }else{
                            print("LIB >>>> GET RES THAI ID ERROR ")
                        } // End of get response Thai id p2
                    }else{
                        print("LIB >>>> READ BINARY THAI ID 2")
                    } // End of Read binary thai id 2
                }else{
                    print("LIB >>>> SELECT THAI ID ERROR ")
                } // End of select thai id
                
                if isImageRequire {
                    
                    print("""
                    
                    #####################################
                              GET THAI Picture
                    #####################################
                    
                    """)
                    
                    // MARK: - Step 9 : Send APDU for read binary image p1
                    var imgHex:String = ""
                    var i = 0
                    while i < 20 {
                        print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apduImg[i])
                        res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apduImg[i])
                        print("LIB <<<< (APDU RES GET THAI ID DATA) <<<< : " + res.uppercased())
                        if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                            
                            // MARK: - Step 10 : Send APDU for recieve data part 2
                            
                            print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apdu.getResponse.rawValue)
                            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                            print("LIB <<<< (APDU RES GET THAI ID DATA) <<<< : " + res.uppercased())
                            if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                                
                                imgHex += res.dropLast(4)
                                i+=1
                            }else{
                                print("LIB >>>> GET BINARY IMG 1")
                                i+=1
                            } // End of get binary img 1
                        }else{
                            print("LIB >>>> READ BINARY IMG 1")
                            i+=1
                        } // End of read binary img 1
                    }
                    
                    model?.base64Img = imgHex.hexadecimal?.base64EncodedString()
                    print("LIB >>>> " + (model?.base64Img)!)
                    
                }
                

            }
            
        }
        
    }
    
}
