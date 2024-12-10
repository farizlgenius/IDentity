//
//  ReaderController.swift
//  PassportLib
//
//  Created by honorsupplying on 11/24/24.
//

import Foundation
import CryptoTokenKit

protocol ReaderControllerDelegate {
    func onErrorOccur(errorMessage:String,isError:Bool)
}

class ReaderController
{
    // Reader Controller Properties
    var mngr:TKSmartCardSlotManager?
    var card:TKSmartCard?
    var slot:TKSmartCardSlot?
    var delegate:ReaderControllerDelegate?
    var isPassport:Bool
    
    init(isPassport:Bool){
        mngr = TKSmartCardSlotManager.default
        self.isPassport = isPassport
    }
    
    func initSmartCard() async ->Bool{
        let readerName = getReader()
        slot = await mngr?.getSlot(withName: readerName)
        if slot != nil {
            print("LIB >>>> Init Smart Card Success")
            return true
        }
        print("LIB >>>> Init Smart Card Fail")
        delegate?.onErrorOccur(errorMessage: "Init Smart Card Fail !!!", isError: true)
        return false
    }
    
    // get reader name
    func getReader()->String{
        if (mngr?.slotNames.count)! > 0 {
            if isPassport {
                for reader in mngr!.slotNames {
                    if reader == "Feitian R502   " {
                        return "Feitian R502   "
                    }
                }
                
                print("LIB >>>> Reader : " + (mngr?.slotNames[0])!)
                //print(mngr?.slotNames)
                return (mngr?.slotNames[0])!
                
            }else{
                for reader in mngr!.slotNames {
                    if reader == "Feitian SCR301" {
                        return "Feitian SCR301"
                    }
                }
                
                print("LIB >>>> Reader : " + (mngr?.slotNames[0])!)
                //print(mngr?.slotNames)
                return (mngr?.slotNames[0])!
            }
            
        }else{
            print("LIB >>>> No Reader Found")
            delegate?.onErrorOccur(errorMessage: "No Reader Found !!!", isError: true)
             return "No Reader"
        }
    }
    
        
    // begin smart card session
    func beginCardSession() async -> Bool {
        card = slot!.makeSmartCard()
        if let card = card {
            do {
                print("LIB >>>> Begin Card Session Success")
                return try await card.beginSession()
            } catch {
                print("LIB >>>> Begin Card Session Fail, No Smart Card Found")
                return false
            }
        }else{
            print("LIB >>>> Make Smart Card Slot Fail")
            delegate?.onErrorOccur(errorMessage: "Make Smart Card Slot Fail !!!", isError: true)
            return false
        }
        
    }
    
    // Transmit APDU to Card
    func transmitCardAPDU(card:TKSmartCard,apdu:String) async -> String {
        let data = NSData(bytes: apdu.hexaBytes, length: apdu.hexaData.count)
        do{
            let res = try await card.transmit(data as Data)
            return res.hexadecimal
        } catch {
            return "nil"
        }
    }
    
    // End Card Session
    func endCardSession(){
        if card != nil {
            card!.endSession()
            card = nil
            slot = nil
            mngr = nil
            print("LIB >>>> End Card Session Success")
        }else{
            print("LIB >>> Can't End Card Session no Smart Card Found!!")
        }
        
    }
}
