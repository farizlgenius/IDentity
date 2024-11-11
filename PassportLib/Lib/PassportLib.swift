//
//  PassportLib.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 8/11/2567 BE.
//

import Foundation
import CryptoTokenKit
import CryptoKit
import CommonCrypto

class PassportLib
{
    // APDU Command
    let SELECTDFSTR:String = "00A4040007A0000002471001"
    let GETCHALLENGESTR:String = "0084000008"
    
    
    let mngr:TKSmartCardSlotManager?
    let util:Utility?
    
    init(){
        mngr = TKSmartCardSlotManager.default
        util = Utility()
        
    }
    
    
    func startReadDGData(mrz:String){
        
        
        // Step 1 : Hash MRZ Data with SHA1 Algorithm
        let mrzData = mrz.data(using: .utf8)
        let Kseed = util?.sha1HashData(data: mrzData!).prefix(32)
        
        // MARK: Step 2 / 3 : Calculate Kenc and Kmac from Kseed and adjust Parity
        let Key1 = util?.CalculateKey(Kseed: String(Kseed!))
        let c1:String = Kseed! + "00000001"
        let c2:String = Kseed! + "00000002"
        let Kenc = util?.sha1HashData(data: c1.hexadecimal!).prefix(32)
        let Kmac = util?.sha1HashData(data: c2.hexadecimal!).prefix(32)
        
        // Step 3 : Adjust key parity
        let KencA = Key1![0]
        let KmacA = Key1![1]
        
        print("Kenc : " + KencA!)
        print("Kmac : " + KmacA!)
        
        
        // use first reader found
        let slotName = mngr?.slotNames[0] ?? "nil"
        print("slotName: " + slotName)
        
        // connect to the card
        mngr?.getSlot(withName: slotName, reply: {
            (slot:TKSmartCardSlot?) in
            let card = slot?.makeSmartCard()
            if card != nil {
                // begin session
                card?.beginSession{
                   ( success:Bool,error:Error?) in
                    if success {
                        // Send Data for Select DF
                        let data = NSData(bytes: self.SELECTDFSTR.hexaBytes, length: self.SELECTDFSTR.hexaData.count)
                        card?.transmit(data as Data, reply: { (data:Data?,error:Error?) in
                            if error != nil {
                                print("error : ",error!)
                            }else{
                                print("response : ",data?.hexadecimal ?? "nil")
                                
                                // MARK: Step 5 : Request 8 byte random number from Passport
                                /*
                                 Send APDU Command : 0084000008
                                 */
                                
                                let data2 = NSData(bytes: self.GETCHALLENGESTR.hexaBytes, length: self.GETCHALLENGESTR.hexaData.count)
                                card?.transmit(data2 as Data, reply: {
                                    (data:Data?,error:Error?) in
                                    if error != nil {
                                        print("error : ",error!)
                                    }else{
                                        
                                        // MARK: Step 4 : Generate random 8 byte hex and 16 byte hex
                                        
                                        let Kifd = self.util?.RandomHex(numDigit: 32)
                                        let RNDIFD = self.util?.RandomHex(numDigit: 16)
                                        let RNDIC = data?.hexadecimal.dropLast(4)
                                        print("response : ",data?.hexadecimal ?? "nil")
                                        print("RNDIC : " + RNDIC!)
                                        
                                        // MARK: Step 5 : Concat RNDIFD + RNDIC + Kifd
                                        
                                        let S = RNDIFD! + RNDIC! + Kifd!
                                        print("S : " + S)
                                        
                                        // MARK: Step 6 : Encrypt S with 3DES KencA
                                        
                                        let Eifd = self.util?.TripleDesEncCBC(input: S, key: KencA!)
                                        print("Eifd : " + Eifd!)
                                        
                                        // MARK: Step 7 : Calculate MAC over Eifd with KmacA
                                        
                                        let Mifd = self.util?.MessageAuthenticationCodeMethodTwo(input: Eifd!, key: KmacA!)
                                        print("Mifd : " + Mifd!)
                                        
                                        // MARK: Step 8 : Construct cmd for EXTERNAL AUTHENTICATION : cmd_data = Eifd + Mifd
                                        
                                        let cmd_data = Eifd! + Mifd!
                                        let EXAuthenticationAPDU = "0082000028" + cmd_data + "28"
                                        print("EXauthen cmd : " + EXAuthenticationAPDU)
                                        let data3 = NSData(bytes: EXAuthenticationAPDU.hexaBytes, length: EXAuthenticationAPDU.hexaData.count)
                                        card?.transmit(data3 as Data,reply: {
                                            (data:Data?,error:Error?) in
                                            if error != nil {
                                                print("error : ",error!)
                                            }else{
                                                
                                                // MARK: Step 9 : Decrypt Response
                                                
                                                let Eic = data?.hexadecimal.dropLast(20)
                                                if (data?.hexadecimal.count)! > 4 {
                                                    let R = self.util?.TripleDesDecCBC(input: String(Eic!), key: KencA!)
                                                    print("Eic : " + Eic!)
                                                    
                                                    // MARK: Step 10 : Calculate Kic and SSC
                                                    
                                                    let Kic = String((R?.dropFirst(32))!)
                                                    print("Kic : " + Kic)
                                                    let a = R?.dropLast(32)
                                                    let b = a?.dropFirst(16)
                                                    let c = a?.dropLast(16)
                                                    let SSC = (b?.dropFirst(8))! + (c?.dropFirst(8))!
                                                    print("SSC : " + SSC)
                                                    
                                                    // MARK: Step 11 : Calculate Kseed from XOR of Kic and Kifd
                                                    
                                                    let SKseed = self.util?.XOR(Data1: Kic, Data2: Kifd!)
                                                    print("SKseed : " + SKseed!)
                                                    
                                                    // MARK: Step 12 : Calculate KSenc and KSmac from SKeed
                                                    
                                                    let Key2 = self.util?.CalculateKey(Kseed: SKseed!)
                                                    let SKenc = Key2![0]
                                                    let SKmac = Key2![1]
                                                    print("SKenc : " + SKenc!)
                                                    print("SKmac : " + SKmac!)
                                                    
                                                    // MARK: Step 13 : Generate APDU for SELECT DG1
                                                    
                                                    let CmdHead = "0CA4020C80000000"
                                                    let data = "0101800000000000"
                                                    let EncData = self.util?.TripleDesEncCBC(input: data, key: SKenc!)
                                                    let DO87 = "870901" + EncData!
                                                    let M = CmdHead + DO87
                                                    print("M : " + M)
                                                    
                                                    let SSC1 = self.util?.IncrementHex(Hex: String(SSC), Increment: 1)
                                                    print("SSC + 1 : " + SSC1!)
                                                    
                                                    
                                                    
                                                    
                                                }else{
                                                    print("Res : " + data!.hexadecimal)
                                                }
      
                                                
                                            }
                                        })
                                    }
                                })
                            }
                        })
                        
                    }else{
                        print("Session error:",error!)
                    }
                }
            }else{
                print("No card found")
            }
        })
        
    }
    
    
}
