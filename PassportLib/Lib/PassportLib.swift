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
    enum DG : String{
        case DG1 = "0101"
        case DG2 = "0102"
        case DG3 = "0103"
        case DG4 = "0104"
        case DG5 = "0105"
        case DG6 = "0106"
        case DG7 = "0107"
        case DG8 = "0108"
        case DG9 = "0109"
        case DG10 = "010A"
        case DG11 = "010B"
    }
    // APDU Command
    let SELECTDFSTR:String = "00A4040007A0000002471001"
    let GETCHALLENGESTR:String = "0084000008"
    
    
    let mngr:TKSmartCardSlotManager?
    let util:Utility?
    
    init(){
        mngr = TKSmartCardSlotManager.default
        util = Utility()
        
    }
    
    func ConstructAPDUforSelectDF(DG:String,SKenc:String,SKmac:String,SSC1:String) -> String{
        let CmdHead = "0CA4020C80000000"
        let data = DG + "800000000000"
        let EncData = self.util?.TripleDesEncCBC(input: data, key: SKenc)
        print("EncData : " + EncData!)
        let DO87 = "870901" + EncData!
        let M = CmdHead + DO87
        print("M : " + M)
        
//        var SSC1 = self.util?.IncrementHex(Hex: String(SSC), Increment: 1)
//        print("SSC + 1 : " + SSC1!)
        
        let N = SSC1 + M + "8000000000"
        print("N : " + N)
        
        print("SKmac : " + SKmac)

        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: N, key: SKmac)
        
        let DO8E = "8E08" + CC!
        
        return "0CA4020C15" + DO87 + DO8E + "00"
    }
    
    func VerifySelectRAPDU(APDU:String,SSC:String,Key:String)->Bool{
        let RAPDU = APDU.dropLast(4).uppercased()
        let DropIndex = RAPDU.count - (self.util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!
        let K = SSC + RAPDU.dropLast(DropIndex) + "80000000"
        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: K, key: Key)
        let DO8E = RAPDU.dropFirst((self.util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!+4)
        if CC! == DO8E {
            return true
        }else{
            return false
        }
    }
    
    func ConstructAPDUforReadBinary(HexBlock:String,HexOffset:String,HexLength:String,SSC:String,SKmac:String)->String{
        let CmdHeader = "0CB0\(HexBlock)\(HexOffset)80000000"
        let DO97 = "9701\(HexLength)"
        let M = CmdHeader + DO97
        let N = SSC + M + "8000000000"
        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: N, key: SKmac)
        let DO8E = "8E08" + CC!
        let ProtectedAPDU = "0CB0\(HexBlock)\(HexOffset)0D" + DO97 + DO8E + "00"
        return ProtectedAPDU
    }
    
    func VerifyReadBinaryRAPDU(APDU:String,SSC:String,Key:String)->Bool{
        let RAPDU = APDU.dropLast(4).uppercased()
        let DropIndex = RAPDU.count - (self.util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!
        let K = SSC + RAPDU.dropLast(DropIndex) + "80"
        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: K, key: Key)
        let DO8E = RAPDU.dropFirst((self.util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!+4)
        if CC! == DO8E {
            return true
        }else{
            return false
        }
    }
    
    func GetLengthOfData(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(6)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(2))!
        let index = result.count - (util?.FindIndexOf(inputString: String(result), target: "5F1F"))!
        let length = result.dropLast(index)
        return String(length)
    }
    
    func GetData(APDU:String,SKenc:String)->String{
        let result = APDU.dropFirst(6).uppercased()
        let result2 = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "9902"))!)
        let result3 = util?.TripleDesDecCBC(input: String(result2), key: SKenc)
        return hexStringtoAscii(result3!)
    }
    
    func hexStringtoAscii(_ hexString : String) -> String {

        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = hexString as NSString
        let matches = regex.matches(in: hexString, options: [], range: NSMakeRange(0, nsString.length))
        let characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }
        return String(characters)
    }
    
    
    
    func startReadDGData(mrz:String){
        
        
        // Step 1 : Hash MRZ Data with SHA1 Algorithm
        let mrzData = mrz.data(using: .utf8)
        let Kseed = util?.sha1HashData(data: mrzData!).prefix(32)
        
        // MARK: Step 2 / 3 : Calculate Kenc and Kmac from Kseed and adjust Parity
        let Key1 = util?.CalculateKey(Kseed: String(Kseed!))
        
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
                                        if data?.hexadecimal.count == 4 {
                                            print("Res : " + data!.hexadecimal)
                                            card?.endSession()
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
                                                    
                                                    print("EX res : " + data!.hexadecimal)
                                                    let Eic = data?.hexadecimal.dropLast(20)
                                                    print("Eic : " + Eic!)
                                                    if (data?.hexadecimal.count)! > 4 {
                                                        let R = self.util?.TripleDesDecCBC(input: String(Eic!), key: KencA!)
                                                        
                                                        // MARK: Step 10 : Calculate Kic and SSC
                                                        
                                                        let Kic = String((R?.dropFirst(32))!)
                                                        print("Kic : " + Kic)
                                                        let a = R?.dropLast(32)
                                                        let b = a?.dropLast(16)
                                                        let c = a?.dropFirst(16)
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
                                                        
                                                        var SSC1 = self.util?.IncrementHex(Hex: String(SSC), Increment: 1)
                                                        var ProtectedAPDU = self.ConstructAPDUforSelectDF(DG:DG.DG1.rawValue,SKenc: SKenc!,SKmac: SKmac!,SSC1: String(SSC1!))
                                                        
                                                        
                                                        // MARK: Step 14 : Send APDU for select DG1
                                                        print("Select cmd : " + ProtectedAPDU)
                                                        var APDUCmd = NSData(bytes: ProtectedAPDU.hexaBytes, length: ProtectedAPDU.hexaData.count)
                                                        card?.transmit(APDUCmd as Data, reply: {
                                                            (data:Data?,error:Error?) in
                                                            if error != nil {
                                                                print("error : ",error!)
                                                            }else{
                                                                print("RAPDU : " + data!.hexadecimal)
                                                                SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                var re = self.VerifySelectRAPDU(APDU: data!.hexadecimal, SSC: SSC1!, Key: SKmac!)
                            
                                                                if re {
                                                                    print("Compare CC success")
                                                                    
                                                                    // MARK: Read Binary to find length of data inside DG1
                                                                    
                                                                    SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                    
                                
                                                                    
                                                                    ProtectedAPDU = self.ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "04", SSC: SSC1!, SKmac: SKmac!)
                                                                    
                                                                    APDUCmd = NSData(bytes: ProtectedAPDU.hexaBytes, length: ProtectedAPDU.hexaData.count)
                                                                    card?.transmit(APDUCmd as Data, reply: { [self]
                                                                        (data:Data? ,error:Error?) in
                                                                        if error != nil {
                                                                            print(error!)
                                                                        }else{
                                                                            print("RAPDU : " + data!.hexadecimal)
                                                                            SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                            re = self.VerifyReadBinaryRAPDU(APDU: data!.hexadecimal, SSC: SSC1!, Key: SKmac!)
                                                                            if re {
                                                                                print("Verify CC for Read Binary Success")
                                                                                // GetLength
                                                                                let Datalength = self.GetLengthOfData(APDU: data!.hexadecimal, SKenc: SKenc!)
                                                                                print(Datalength)
                                                                                
                                                                                // MARK: Get Data of DG 1
                                                                                
                                                                                SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                                ProtectedAPDU = self.ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "05", HexLength:Datalength , SSC: SSC1!, SKmac: SKmac!)
                                                                                APDUCmd = NSData(bytes: ProtectedAPDU.hexaBytes, length: ProtectedAPDU.hexaData.count)
                                                                                card?.transmit(APDUCmd as Data, reply: {
                                                                                    (data:Data?,error:Error?) in
                                                                                    if error != nil {
                                                                                        print(error!)
                                                                                    }else{
                                                                                        print("RAPDU : " + data!.hexadecimal)
                                                                                        SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                                        re = self.VerifyReadBinaryRAPDU(APDU: data!.hexadecimal, SSC: SSC1!, Key: SKmac!)
                                                                                        if re {
                                                                                            print("Verify CC for Read Binary Success")
                                                                                            print("DG1 : " + self.GetData(APDU: data!.hexadecimal, SKenc: SKenc!))
                                                                                            
                                                                                            // MARK: Generate APDU for SELECT DG11
                                                                                            
                                                                                            SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                                            let ProtectedAPDU = self.ConstructAPDUforSelectDF(DG:DG.DG11.rawValue,SKenc: SKenc!,SKmac: SKmac!,SSC1: String(SSC1!))
                                                                                            
                                                                                            
                                                                                            // MARK: Send APDU for select DG11
                                                                                            
                                                                                            print("Select cmd : " + ProtectedAPDU)
                                                                                            let APDUCmd = NSData(bytes: ProtectedAPDU.hexaBytes, length: ProtectedAPDU.hexaData.count)
                                                                                            card?.transmit(APDUCmd as Data, reply: {
                                                                                                (data:Data?,error:Error?) in
                                                                                                if error != nil {
                                                                                                    print(error!)
                                                                                                }else{
                                                                                                    if (data?.hexadecimal.count)! <= 4 {
                                                                                                        print("RAPDU : " + data!.hexadecimal)
                                                                                                    }else{
                                                                                                        print("RAPDU : " + data!.hexadecimal)
                                                                                                        SSC1 = self.util?.IncrementHex(Hex: SSC1!, Increment: 1)
                                                                                                        let re = self.VerifySelectRAPDU(APDU: data!.hexadecimal, SSC: SSC1!, Key: SKmac!)
                                                                                                        if re {
                                                                                                            print("Verify CC success for select DG11")
                                                                                                            
                                                                                                            // MARK: Get Length Data of DG11
                                                                                                            
                                                                                                            
                                                                                                        }else{
                                                                                                            print("Verify CC fail for select DG11")
                                                                                                        }
                                                                                                    }
                                                                                                    
                                                                                                }
                                                                                            })
                                                                                            
                                                                                            
                                                                                            
                                                                                        }else{
                                                                                            print("Verify CC for Read Binary Fail")
                                                                                        }
                                                                                    }
                                                                                })
                                                                            }else{
                                                                                print("Verify CC for Read Binary Fail")
                                                                                card?.endSession()
                                                                            }
                                                                        }
                                                                    })
                                                                    
                                                                    
                                                                }else{
                                                                    print("Compare CC fail for Select DG1")
                                                                    card?.endSession()
                                                                }
                                                            }
                                                        })
                                                        
                                                    }else{
                                                        print("Res : " + data!.hexadecimal)
                                                    }
 
                                                }
                                            })
                                        }
    
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
