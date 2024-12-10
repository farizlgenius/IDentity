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
    func onCompleteReadThaiIdData(data:ThaiIdModel)
    func onBeginCardSession(isSuccess:Bool)
    func onErrorOccur(errorMessage:String,isError:Bool)
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
        case readAddress = "80B015790200FF"
        //case getResponseAddress = "00C00000FF"
    }
    
    var apduImg:[String] = ["80B0017B0200FF","80B0027A0200FF","80B003790200FF","80B004780200FF","80B005770200FF","80B006760200FF","80B007750200FF","80B008740200FF","80B009730200FF","80B00A720200FF","80B00B710200FF","80B00C700200FF","80B00D6F0200FF","80B00E6E0200FF","80B00F6D0200FF","80B0106C0200FF","80B0116B0200FF","80B0126A0200FF","80B013690200FF","80B014680200FF"]
    
    // Properties
    let rmngr:ReaderController
    var isSmartCardInitialized:Bool?
    var isCardSessionBegin:Bool?
    let util:Utility?
    var data:ThaiIdModel?
    var progress:Float = 0.0
    var eachProgress:Float = 0.0
    var slotName:String = ""
    
    // Delegate
    var delegate:ThaiIdControllerDelegate?
    
    // Constructor
    init(rmngr:ReaderController,isSmartCardInitialized:Bool){
        util = Utility()
        data = ThaiIdModel()
        self.rmngr = rmngr
        self.isSmartCardInitialized = isSmartCardInitialized
    }
    
    // function convert to thai language
    func ConvertToThai(input:String) -> String {
        if input != "" {
            let inputData = input.hexadecimal
            let inputBytes = (inputData! as NSData).bytes
            let inputResult = CFStringCreateWithBytes(kCFAllocatorDefault, inputBytes, inputData!.count, CFStringEncoding(CFStringEncodings.isoLatinThai.rawValue), false)
            let result = inputResult as? String
            return (result?.trimmingCharacters(in: .whitespacesAndNewlines))!
        }else{
            return ""
        }
        
    }
    
    
    func getChipID() async {
        print("""
        
        #####################################
                    GET CHIP ID 
        #####################################
        
        """)
        
        // MARK: - Step 2 : Send APDU for Get Chip ID
        //print("LIB >>>> (APDU CMD GET CHIP ID) >>>> : " + apdu.chipId.rawValue)
        print("LIB >>>> (APDU CMD GET CHIP ID) >>>> ")
        let res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.chipId.rawValue)
        print("LIB <<<< (APDU RES GET CHIP ID) <<<< : " + res.uppercased())
        if res.uppercased().suffix(4) == "9000" {
            data?.chipId = String(res.uppercased().dropFirst(26).dropLast(52))
        }else{
            print("LIB >>>> GET CHIP ID ERROR ")
            delegate?.onErrorOccur(errorMessage: "GET CHIP ID ERROR !!!", isError: true)
        }
        print("LIB >>>> Chip ID : " + (data?.chipId ?? "nil") )
        
        print("""
        
        #####################################
                    END CHIP ID 
        #####################################
        
        """)
    }
    
    func getLaserId() async {
        print("""
        
        #####################################
                    GET LASER ID
        #####################################
        
        """)
        
        // MARK: - Step 3 : Send APDU for Select Laser ID
        //print("LIB >>>> (APDU CMD SELECT LASER ID) >>>> : " + apdu.laserId.rawValue)
        print("LIB >>>> (APDU CMD SELECT LASER ID) >>>> ")
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.laserId.rawValue)
        print("LIB <<<< (APDU RES SELECT LASER ID) <<<< : " + res.uppercased())
        if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
            
            // MARK: - Step 4 : Send APDU for get Laser ID
            //print("LIB >>>> (APDU CMD GET LASER ID) >>>> : " + apdu.getLaserId.rawValue)
            print("LIB >>>> (APDU CMD GET LASER ID) >>>> ")
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getLaserId.rawValue)
            print("LIB <<<< (APDU RES GET LASER ID) <<<< : " + res.uppercased())
            let filter = res.dropFirst(14).dropLast(12)
            print("LIB >>>> Laser ID :  " + util!.hexStringtoAscii(String(filter)))
            if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                data?.laserId = util!.hexStringtoAscii(String(filter))
            }else{
                print("LIB >>>> GET LASER ID ERROR ")
                delegate?.onErrorOccur(errorMessage: "GET LASER ID ERROR !!!", isError: true)
            } // End of get laser id

        }else{
            print("LIB >>>> SELECT LASER ID ERROR ")
            delegate?.onErrorOccur(errorMessage: "SELECT LASER ID ERROR !!!", isError: true)
        } // End of select laser id
        
        print("""
        
        #####################################
                    END LASER ID
        #####################################
        
        """)
    }
    
    func getPersonalData() async {
        
        print("""
        
        #####################################
                  GET THAI ID DATA 
        #####################################
        
        """)
        
        // MARK: - Step 4 : Send APDU for Select Thai ID Card Data
        print("LIB >>>> (APDU CMD SELECT THAI ID DATA) >>>> " )
        //print("LIB >>>> (APDU CMD SELECT THAI ID DATA) >>>> : " + apdu.selectThaiIdDf.rawValue)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.selectThaiIdDf.rawValue)
        print("LIB <<<< (APDU RES SELECT THAI ID DATA) <<<< : " + res.uppercased())
        if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
            
            // MARK: - Step 4 : Send APDU for get Laser ID
            //print("LIB >>>> (APDU CMD READ BINARY THAI ID DATA P1) >>>> : " + apdu.readBinary1.rawValue)
            print("LIB >>>> (APDU CMD READ BINARY THAI ID DATA P1) >>>> ")
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.readBinary1.rawValue)
            print("LIB <<<< (APDU RES READ BINARY TAHI ID DATA P1) <<<< : " + res.uppercased())
            if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                
                
                // MARK: - Step 6 : Send APDU for recieve data part 1
                
                //print("LIB >>>> (APDU CMD GET THAI ID DATA P1) >>>> : " + apdu.getResponse.rawValue)
                print("LIB >>>> (APDU CMD GET THAI ID DATA P1) >>>> ")
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                print("LIB <<<< (APDU RES GET THAI ID DATA P1) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                    
                    // Card Type
                    data?.cardType = util!.hexStringtoAscii(String(res.prefix(8)))
                    print("LIB >>>> Card Type :  " +  (data?.cardType)!)
                    res = String(res.dropFirst(8))
                    
                    // Thai ID
                    data?.cId = util?.hexStringtoAscii(String(res.prefix(26)))
                    print("LIB >>>> Thai ID :  " +  (data?.cId)!)
                    res = String(res.dropFirst(26))
                    
                    // Thai Full Name
                    var thFullName = res.prefix(200)
                    data?.thaiFullName = ConvertToThai(input:String(thFullName)).replacingOccurrences(of: "#", with: " ")
                    print("LIB >>>> Thai Full Name :  " +  (data?.thaiFullName)!)
                    
                    // Thai Title Name
                    var indexOf23 = util?.FindIndexOf(inputString: String(thFullName), target: "23")
                    let thTitleName = String(thFullName.prefix(indexOf23!))
                    data?.thaiTitleName = ConvertToThai(input: thTitleName)
                    print("LIB >>>> Thai First Name :  " +  (data?.thaiTitleName)!)
                    thFullName = thFullName.dropFirst(indexOf23! + 2)
                    
                    // Thai First Name
                    indexOf23 = util?.FindIndexOf(inputString: String(thFullName), target: "23")
                    let thFirstName = String(thFullName.prefix(indexOf23!))
                    data?.thaiFirstName = ConvertToThai(input: thFirstName)
                    print("LIB >>>> Thai Title Name :  " +  (data?.thaiFirstName)!)
                    thFullName = thFullName.dropFirst(indexOf23! + 2)
                    
                    // Thai Middle Name
                    indexOf23 = util?.FindIndexOf(inputString: String(thFullName), target: "23")
                    let thMiddleName = String(thFullName.prefix(indexOf23!))
                    data?.thaiMiddleName = ConvertToThai(input: thMiddleName)
                    print("LIB >>>> Thai Middle Name :  " +  (data?.thaiMiddleName)!)
                    thFullName = thFullName.dropFirst(indexOf23! + 2)
                    
                    // Thai Last Name
                    let thLastName = String(thFullName)
                    data?.thaiLastName = ConvertToThai(input: thLastName)
                    print("LIB >>>> Thai Last Name :  " +  (data?.thaiLastName)!)
                    res = String(res.dropFirst(200))
                    
                    // Eng Full Name
                    var enFullName = res.prefix(200)
                    data?.engFullName = util?.hexStringtoAscii(String(enFullName)).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: " ")
                    print("LIB >>>> Eng Full Name :  " +  (data?.engFullName)!)
                    
                    // Eng Title Name
                    indexOf23 = util?.FindIndexOf(inputString: String(enFullName), target: "23")
                    let enTitleName = String(enFullName.prefix(indexOf23!))
                    data?.engTitleName = util?.hexStringtoAscii(enTitleName).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("LIB >>>> Eng Title Name :  " +  (data?.engTitleName)!)
                    enFullName = enFullName.dropFirst(indexOf23! + 2)
                    
                    // Eng First Name
                    indexOf23 = util?.FindIndexOf(inputString: String(enFullName), target: "23")
                    let enFirstName = String(enFullName.prefix(indexOf23!))
                    data?.engFirstName = util?.hexStringtoAscii(enFirstName).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("LIB >>>> Eng First Name :  " +  (data?.engFirstName)!)
                    enFullName = enFullName.dropFirst(indexOf23! + 2)
                    
                    // Eng Middle Name
                    indexOf23 = util?.FindIndexOf(inputString: String(enFullName), target: "23")
                    let enMiddleName = String(enFullName.prefix(indexOf23!))
                    data?.engMiddleName = util?.hexStringtoAscii(enMiddleName).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("LIB >>>> Eng Middle Name :  " +  (data?.engMiddleName)!)
                    enFullName = enFullName.dropFirst(indexOf23! + 2)
                    
                    // Eng Last Name
                    let enLastName = String(enFullName)
                    data?.engLastName = util?.hexStringtoAscii(enLastName).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("LIB >>>> Eng Last Name :  " +  (data?.engLastName)!)
                    res = String(res.dropFirst(200))
                    
                    // Birth Date
                    data?.dateOfBirth = util?.hexStringtoAscii(String(res.prefix(16)))
                    print("LIB >>>> Birth Date :  " +  (data?.dateOfBirth)!)
                    res = String(res.dropFirst(16))
                    
                    // Gender
                    data?.gender = util?.hexStringtoAscii(String(res.prefix(2)))
                    print("LIB >>>> Gender :  " +  (data?.gender)!)
                    res = String(res.dropFirst(2))
                    
                    // Bp1no
                    data?.bp1no = util?.hexStringtoAscii(String(res.prefix(40)))
                    print("LIB >>>> BP1No :  " +  (data?.bp1no)!)
                    res = String(res.dropFirst(40))
                    
                    // Card Issuer p1
                    data?.cardIssuer = ConvertToThai(input: String(res.dropLast(4)))
                    
                    
                }else{
                    print("LIB >>>> GET RES THAI ID ERROR ")
                    delegate?.onErrorOccur(errorMessage: "GET RES THAI ID ERROR !!!", isError: true)
                } // End of get response Thai id p1
            }else{
                print("LIB >>>> READ BINARY THAI ID DATA P1 ERROR!!!")
                delegate?.onErrorOccur(errorMessage: "READ BINARY THAI ID DATA P1 ERROR !!!", isError: true)
            } // End of Read binary thai id 1
            
            // MARK: - Step 7 : Send APDU for read binary data part 2
            
            //print("LIB >>>> (APDU CMD READ BINARY ID DATA P2) >>>> : " + apdu.readBinary2.rawValue)
            print("LIB >>>> (APDU CMD READ BINARY ID DATA P2) >>>> ")
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.readBinary2.rawValue)
            print("LIB <<<< (APDU RES READ BINARY ID DATA P2) <<<< : " + res.uppercased())
            if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                
                // MARK: - Step 8 : Send APDU for recieve data part 2
                
                //print("LIB >>>> (APDU CMD GET THAI ID DATA P2) >>>> : " + apdu.getResponse.rawValue)
                print("LIB >>>> (APDU CMD GET THAI ID DATA P2) >>>> ")
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                print("LIB <<<< (APDU RES GET THAI ID DATA P2) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                    
                    // Card Issuer p2
                    data?.cardIssuer! += ConvertToThai(input: String(res.prefix(182)))
                    print("LIB >>>> Card Issuer :  " +  (data?.cardIssuer)!)
                    res = String(res.dropFirst(182))
                    
                    // Issuer Code
                    data?.issuerCode = util?.hexStringtoAscii(String(res.prefix(26)))
                    print("LIB >>>> Issuer Code :  " +  (data?.issuerCode)!)
                    res = String(res.dropFirst(26))
                    
                    // Date of Issue
                    data?.issueDate = util?.hexStringtoAscii(String(res.prefix(16)))
                    print("LIB >>>> Issue Date :  " +  (data?.issueDate)!)
                    res = String(res.dropFirst(16))
                    
                    // Expire Date
                    data?.expireDate = util?.hexStringtoAscii(String(res.prefix(16)))
                    print("LIB >>>> Expire Date :  " +  (data?.expireDate)!)
                    res = String(res.dropFirst(16))
                    
                }else{
                    print("LIB >>>> GET RES THAI ID ERROR ")
                    delegate?.onErrorOccur(errorMessage: "GET RES THAI ID ERROR !!!", isError: true)
                } // End of get response Thai id p2
            }else{
                print("LIB >>>> READ BINARY THAI ID DATA P2 ERROR!!!")
                delegate?.onErrorOccur(errorMessage: "READ BINARY THAI ID DATA P2 ERROR!!!", isError: true)
            } // End of Read binary thai id 2
            
            // MARK: - Step 9 : Send APDU for read binary address
            //print("LIB >>>> (APDU CMD READ BINARY ADDRESS) >>>> : " + apdu.readAddress.rawValue)
            print("LIB >>>> (APDU CMD READ BINARY ADDRESS) >>>> ")
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.readAddress.rawValue)
            print("LIB <<<< (APDU RES READ BINARY ADDRESS) <<<< : " + res.uppercased())
            if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                
                // MARK: - Step 8 : Send APDU for recieve address
                
                //print("LIB >>>> (APDU CMD GET THAI ID ADDRESS) >>>> : " + apdu.getResponse.rawValue)
                print("LIB >>>> (APDU CMD GET THAI ID ADDRESS) >>>> ")
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                print("LIB <<<< (APDU RES GET THAI ID ADDRESS) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                    
                    let photoref = res.dropFirst(320).prefix(28)
                    print(photoref)
                    
                    // Address
                    let address = ConvertToThai(input: String(res.prefix(320)))
                    let adrArr = address.components(separatedBy: "#")
                    data?.address = adrArr[0]
                    print("LIB >>>> Address :  " +  (data?.address)!)
                    data?.moo = adrArr[1]
                    print("LIB >>>> Moo :  " +  (data?.moo)!)
                    data?.trok = adrArr[2]
                    print("LIB >>>> Trok :  " +  (data?.trok)!)
                    data?.soi = adrArr[3]
                    print("LIB >>>> Soi :  " +  (data?.soi)!)
                    data?.thanon = adrArr[4]
                    print("LIB >>>> Thanon :  " +  (data?.thanon)!)
                    data?.tumbol = adrArr[5]
                    print("LIB >>>> Tumbol :  " +  (data?.tumbol)!)
                    data?.amphur = adrArr[6]
                    print("LIB >>>> Amphur :  " +  (data?.amphur)!)
                    data?.provice = adrArr[7]
                    print("LIB >>>> Province :  " +  (data?.provice)!)
                    

                    
                    
                    // PhotoRefNumber
                    data?.photoRefNumber = util?.hexStringtoAscii(String(photoref))
                    print("LIB >>>> Photo Reference Number :  " +  (data?.photoRefNumber)!)
                    res = String(res.dropFirst(16))
                    
                }else{
                    print("LIB >>>> GET RES THAI ID ERROR ")
                    delegate?.onErrorOccur(errorMessage: "GET RES THAI ID ERROR !!!", isError: true)
                } // End of get response Thai id p2
            }else{
                print("LIB >>>> READ BINARY THAI ID ADDRESS ERROR!!!")
                delegate?.onErrorOccur(errorMessage: "READ BINARY THAI ID ADDRESS ERROR !!!", isError: true)
            } // End of Read binary thai id 2
            
            
        }else{
            print("LIB >>>> SELECT THAI ID ERROR ")
        } // End of select thai id
        
        
        print("""
        
        #####################################
                  END THAI ID DATA 
        #####################################
        
        """)
        
    }
    
    func getImage() async {
        print("""
        
        #####################################
                  GET THAI Picture
        #####################################
        
        """)
        
        // MARK: - Step 9 : Send APDU for read binary image p1
        var imgHex:String = ""
        var i = 0
        while i < 20 {
            //print("LIB >>>> (APDU CMD GET THAI ID DATA) >>>> : " + apduImg[i])
            print("LIB >>>> (APDU CMD GET THAI ID PIC) >>>> : " + String(i))
            var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apduImg[i])
            print("LIB <<<< (APDU RES GET THAI ID PIC) <<<< : " + res.uppercased())
            if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                
                // MARK: - Step 10 : Send APDU for recieve data part 2
                
                print("LIB >>>> (APDU CMD GET THAI ID PIC) >>>> : " + apdu.getResponse.rawValue)
                print("LIB >>>> (APDU CMD GET THAI ID PIC) >>>> ")
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                print("LIB <<<< (APDU RES GET THAI ID PIC) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" || res.uppercased().prefix(2) == "61" {
                    
                    imgHex += res.dropLast(4)
                    i+=1
                }else{
                    print("LIB >>>> GET BINARY IMG \(i) Error !!!")
                    delegate?.onErrorOccur(errorMessage: "GET BINARY IMG \(i) Error !!!", isError: true)
                    i+=1
                } // End of get binary img 1
            }else{
                print("LIB >>>> READ BINARY IMG \(i)")
                delegate?.onErrorOccur(errorMessage: "READ BINARY IMG \(i)", isError: true)
                i+=1
            } // End of read binary img 1
        }
        
        if imgHex.hexadecimal?.base64EncodedString() != nil {
            data?.base64Img = imgHex.hexadecimal?.base64EncodedString()
        }else{
            data?.base64Img = ""
        }
        
        if data?.base64Img != nil {
            print("LIB >>>> " + (data?.base64Img)!)
        }else{
            print("LIB >>>> Get Image Fail")
        }
        
        
        print("""
        
        #####################################
               END GET THAI Picture
        #####################################
        
        """)
    }
    
    func readThaiID(isImageRequire:Bool) {
        
        // MARK: - Step 1 : Initial SmartCard
        Task.init{
            
            if isSmartCardInitialized! {
                isCardSessionBegin = await rmngr.beginCardSession()
                delegate?.onBeginCardSession(isSuccess: isCardSessionBegin!)
            }
            
            if isCardSessionBegin ?? false {
                
                var progress:Float = 0.0
                await getChipID()
                progress += 0.25
                delegate?.onProgressReadThaiIdData(progress: progress)
                
                await getLaserId()
                progress += 0.25
                delegate?.onProgressReadThaiIdData(progress: progress)
                
                await getPersonalData()
                progress += 0.25
                delegate?.onProgressReadThaiIdData(progress: progress)
               
                
                if isImageRequire {
                    
                    await getImage()
                    progress += 0.25
                    delegate?.onProgressReadThaiIdData(progress: progress)
                    
                }else{
                    data?.base64Img = ""
                    progress += 0.25
                    delegate?.onProgressReadThaiIdData(progress: progress)
                }
                

            }
            
            delegate?.onCompleteReadThaiIdData(data: data!)
            rmngr.endCardSession()
            
        }
        
    }
    
}
