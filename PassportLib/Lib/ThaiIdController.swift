//
//  ThaiIdController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 25/11/2567 BE.
//

import Foundation

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
        case getResponse = "00C0000017"
        case selectThaiIdDf = "00A4040008A000000054480001"
    }
    
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
                }else{
                    model?.chipId = ""
                    print("LIB >>>> GET CHIP ID ERROR ")
                }
                print("LIB >>>> Chip ID : " + (model?.chipId)!)
                delegate?.onProgressReadThaiIdData(progress: 1)
                
                print("""
                
                #####################################
                            GET LASER ID
                #####################################
                
                """)
                
                // MARK: - Step 3 : Send APDU for Select Laser ID
                print("LIB >>>> (APDU CMD SELECT LASER ID) >>>> : " + apdu.laserId.rawValue)
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.chipId.rawValue)
                print("LIB <<<< (APDU RES SELECT LASER ID) <<<< : " + res.uppercased())
                if res.uppercased().suffix(4) == "9000" {
                    
                    // MARK: - Step 4 : Send APDU for get Laser ID
                    print("LIB >>>> (APDU CMD SELECT LASER ID) >>>> : " + apdu.getResponse.rawValue)
                    res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu.getResponse.rawValue)
                    print("LIB <<<< (APDU RES SELECT LASER ID) <<<< : " + res.uppercased())
                    
                }else{
                    print("LIB >>>> SELECT LASER ID ERROR ")
                }
                delegate?.onProgressReadThaiIdData(progress: 1)
                
                // MARK: - Step 3 :
                
            }
            
        }
        
    }
    
}
