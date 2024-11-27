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
import UIKit

protocol PassportControllerDelegate{
    func onProgressReadPassportData(progress:Float)
    func onCompleteReadPassportData(data:PassportModel)
    func onBeginCardSession(isSuccess:Bool)
}

class PassportController
{
    enum DG : String{
        case Common = "011E"
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
        case DG12 = "010C"
        case DG13 = "010D"
        case DG14 = "010E"
        case DG15 = "010F"
        case DG16 = "0110"
    }
    
    enum DGtag : String {
        case Common = "60"
        case DG1 = "61"
        case DG2 = "75"
        case DG3 = "63"
        case DG4 = "76"
        case DG5 = "65"
        case DG6 = "66"
        case DG7 = "67"
        case DG8 = "68"
        case DG9 = "69"
        case DG10 = "6A"
        case DG11 = "6B"
        case DG12 = "6C"
        case DG13 = "6D"
        case DG14 = "6E"
        case DG15 = "6F"
        case DG16 = "70"
    }
    
    
    // APDU Command
    let SELECTDFSTR:String = "00A4040007A0000002471001"
    let GETCHALLENGESTR:String = "0084000008"
    
    // Properties
    let rmngr:ReaderController
    var isSmartCardInitialized:Bool?
    var isCardSessionBegin:Bool?
    let util:Utility?
    var model:PassportModel?
    var progress:Float = 0.0
    var eachProgress:Float = 0.0
    var slotName:String = ""
    var SSCP = ""
    var SKmac = ""
    var SKenc = ""
    
    // Delegate properties
    var delegate:PassportControllerDelegate?
    
    // Constructor
    init(rmngr:ReaderController,isSmartCardInitialized:Bool){
        util = Utility()
        model = PassportModel()
        self.rmngr = rmngr
        self.isSmartCardInitialized = isSmartCardInitialized
    }
    
    
    // APDU function
    func ConstructAPDUforSelectDF(DG:String,SKenc:String,SKmac:String,SSCP:String) -> String{
        let CmdHead = "0CA4020C80000000"
        let data = DG + "800000000000"
        let EncData = self.util?.TripleDesEncCBC(input: data, key: SKenc)
        let DO87 = "870901" + EncData!
        let M = CmdHead + DO87
        let N = SSCP + M + "8000000000"
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
    
    func ConstructAPDUforReadBinaryExtend(HexBlock:String,HexOffset:String,HexLength:String,SSC:String,SKmac:String)->String{
        let CmdHeader = "0CB0\(HexBlock)\(HexOffset)80000000"
        let DO97 = "9702\(HexLength)"
        let M = CmdHeader + DO97
        let N = SSC + M + "80000000"
        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: N, key: SKmac)
        let DO8E = "8E08" + CC!
        let ProtectedAPDU = "0CB0\(HexBlock)\(HexOffset)00000E" + DO97 + DO8E + "0000"
        return ProtectedAPDU
    }
    
    func VerifyReadBinaryRAPDU(APDU:String,SSC:String,Key:String)->Bool{
        let RAPDU = APDU.dropLast(4).uppercased()
        let DropIndex = RAPDU.count - (util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!
        
        var K = SSC + RAPDU.dropLast(DropIndex) + "80"
        while(K.count % 16 != 0){
            K.append("00")
        }
        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: K, key: Key)
        let DO8E = RAPDU.dropFirst((util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!+4)
        if CC! == DO8E {
            return true
        }else{
            return false
        }
    }
    
    func CalculateLenDG1(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(6)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(2))!
        let index = result.count - (util?.FindIndexOf(inputString: String(result), target: "5F1F"))!
        let length = result.dropLast(index)
        return String(length)
    }
    
    func CalculateLenDG2(APDU:String,SKenc:String)->[String]{
        var result = APDU.dropFirst(6)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        //print("result 1 : " + result)
        let encResult = util?.TripleDesDecCBC(input: String(result), key: SKenc)
        print("encResult : " + encResult!)
        // Calculate length of header in biometric template
        let offsetIndex1 = util?.FindIndexOf(inputString: String(encResult!), target: "7F61")
        let offsetIndex2 = encResult!.count - offsetIndex1!
        let offsetValue1 = encResult!.dropLast(offsetIndex2).dropFirst(4)
        let diffValue = UInt32(offsetValue1,radix: 16)! + 4
        let diffValueStr = String(format:"%X",diffValue)
        var offsetIndex3 = util?.FindIndexOf(inputString: String(encResult!), target: "5F2E")
        if offsetIndex3 == -1 {
            offsetIndex3 = util?.FindIndexOf(inputString: String(encResult!), target: "7F2E")
        }
        var offsetValue2 = encResult!.dropFirst(offsetIndex3! + 6)
        offsetValue2 = offsetValue2.dropLast(offsetValue2.count - 4)
        let offsetValue = UInt64(diffValueStr,radix: 16)! - UInt64(offsetValue2,radix: 16)!
        let offset = String(format:"%X",offsetValue)
//        let offsetValue2Diff = UInt32(offsetValue2,radix: 16)! + 2
//        let len = String(format: "%X", offsetValue2Diff)
        let len = offsetValue2
        return [String(len),offset]
    }
    
    
    func GetDataDG2(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(10)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(4))!
        result = result.dropFirst(88).dropLast(6)
        return String(result)
    }
    
    func GetRemainDataDG2(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(10)
        if util?.FindIndexOf(inputString: String(result), target: "99029000") == -1 {
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99026282"))!)
        }else{
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        }
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(4))!
        result = result.dropLast(6)
        return String(result)
    }
    
    func GetDataDG1(APDU:String,SKenc:String)->String{
        let result = APDU.dropFirst(6).uppercased()
        let result2 = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "9902"))!)
        let result3 = util?.TripleDesDecCBC(input: String(result2), key: SKenc)
        print("LIB >>>> DG1 Hex : " + result3!.dropLast(16))
        return hexStringtoAscii(String(result3!.dropLast(16)))
    }
    
    func GetDataDG11(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(6)
        if util?.FindIndexOf(inputString: String(result), target: "99029000") == -1 {
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99026282"))!)
        }else{
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        }
        print("Before ENC : " + result)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(0))!
        //let index = result.count - (util?.FindIndexOf(inputString: String(result), target: "5F10"))!
        return String(result)
    }
    
    func SplitDataDG11(dg11:String,Tag:String)->String{
        if dg11.contains(Tag) {
            let r = dg11.range(of:Tag)?.lowerBound
            let startingIndex = dg11.distance(from: dg11.startIndex, to: r!)
            var data2 = dg11.dropFirst(startingIndex)
            if data2.contains(Tag) {
                data2 = data2.dropFirst(4)
                let r = data2.range(of:Tag)?.lowerBound
                let startingIndex = data2.distance(from: data2.startIndex, to: r!)
                let data3 = data2.dropFirst(startingIndex).dropFirst(4)
                let len = Int(data3.prefix(2),radix: 16)!*2
                let data4 = data3.dropFirst(2).prefix(len)
                print(hexStringtoAscii(String(data4)))
                return hexStringtoAscii(String(data4))
            }
        }
        return ""
    }
    
    func GetDataDG12(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(6)
        if util?.FindIndexOf(inputString: String(result), target: "99029000") == -1 {
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99026282"))!)
        }else{
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        }
        print("Before ENC : " + result)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(0))!
        //let index = result.count - (util?.FindIndexOf(inputString: String(result), target: "5F10"))!
        return String(result)
    }
    
    func GetDataDG15(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(6)
        if util?.FindIndexOf(inputString: String(result), target: "99029000") == -1 {
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99026282"))!)
        }else{
            result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        }
        print("Before ENC : " + result)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(0))!
        //let index = result.count - (util?.FindIndexOf(inputString: String(result), target: "5F10"))!
        return String(result)
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
    
        
    func externalAuthnetication(mrz:String) async -> Bool {
        
        print("""
        
        #####################################
          BEGIN EXTERNAL AUTHENTICATION STEP 
        #####################################
        
        """)
        
        // MARK: - Step 1 : Hash MRZ Data with SHA1 Algorithm
        let mrzData = mrz.data(using: .utf8)
        let Kseed = util?.sha1HashData(data: mrzData!).prefix(32)
        print("LIB >>>> Kseed : " + Kseed!)
        
        // MARK: - Step 2 / 3 : Calculate Kenc and Kmac from Kseed and adjust Parity
        let Key1 = util?.CalculateKey(Kseed: String(Kseed!))
        let Kenc = Key1![0]
        let Kmac = Key1![1]
        
        print("LIB >>>> Kenc : " + Kenc!)
        print("LIB >>>> Kmac : " + Kmac!)
        
        // MARK: - Step 4 : Initial SmartCard
        

        if isSmartCardInitialized! {
            isCardSessionBegin = await rmngr.beginCardSession()
            delegate?.onBeginCardSession(isSuccess: isCardSessionBegin!)
        }
        
        if isCardSessionBegin ?? false {
            
            // MARK: - Step 5 : Transmit APDU for SELECT DF of Passport
            print("LIB >>>> (APDU CMD SELECT DF) >>>> : " + SELECTDFSTR)
            var res = await rmngr.transmitCardAPDU(card:rmngr.card!,apdu: SELECTDFSTR)
            print("LIB <<<< (APDU RES SELECT DF) <<<< : " + res)
            
            // MARK: - Step 6 : Transmit Get Challenge APDU
            print("LIB >>>> (APDU CMD GET CHALLENGE) >>>> : " + GETCHALLENGESTR)
            res = await rmngr.transmitCardAPDU(card:rmngr.card!,apdu: GETCHALLENGESTR)
            print("LIB <<<< (APDU RES GET CHALLENGE) <<<< : " + res.uppercased())
            if res.count <= 4 {
                print("LIB >>>> Can't Get Challenge From Chip")
                print("""
                
                #####################################
                              THE END !!! 
                #####################################
                
                """)
                return false
            }
            let RNDIC = res.uppercased().dropLast(4)
            
            // MARK: - Step 7 : Generate random 8 byte hex and 16 byte hex
            let Kifd = util?.RandomHex(numDigit: 32)
            let RNDIFD = util?.RandomHex(numDigit: 16)
            
            // MARK: - Step 8 : Get S by concatenate RNDIFD + RNDIC + Kifd
            let S = RNDIFD! + RNDIC + Kifd!
            print("LIB >>>> S : " + S)
            
            // MARK: - Step 9 : Get Eifd by Encrypt S with Kenc by 3DES CBC Algorithm
            let Eifd = util?.TripleDesEncCBC(input: S, key: Kenc!)
            print("LIB >>>> Eifd : " + Eifd!)
            
            // MARK: - Step 10 : Get Mifd by Calculate Message Authentication Code Padding Method 2 over Eifd by Kmac
            let Mifd = util?.MessageAuthenticationCodeMethodTwo(input: Eifd!, key: Kmac!)
            print("LIB MSG >>>> Mifd : " + Mifd!)
            
            // MARK: Step 11 : Construct APDU Cmd for do External Authentication Cmd = Eifd concatinate with Mifd
            let apdu = "0082000028" + Eifd! + Mifd! + "28"
            
            // MARK: - Step 12 : Send APDU command
            print("LIB >>>> (APDU CMD EXTERNAL AUTH) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES EXTERNAL AUTH) <<<< : " + res.uppercased())
            
            if res.count <= 4 {
                print("LIB >>>> EXTERNAL AUTHENTICATION Fail")
                print("""
                
                #####################################
                              THE END !!! 
                #####################################
                
                """)
                return false
            }
            // MARK: - Step 13 : Get Eic by Cut Off Mic from response and decrypt Eic to get R
            let Eic = res.uppercased().dropLast(20)
            print("LIB >>>> Eic : " + Eic)
            let R = util?.TripleDesDecCBC(input: String(Eic), key: Kenc!)
            print("LIB >>>> R : " + R!)
      
            //MARK: - Step 14 : Get Kic and SSC from R
            let Kic = R!.dropFirst(32)
            print("LIB >>>> Kic : " + Kic)
            let a = R?.dropLast(32)
            let b = a!.dropLast(16)
            let c = a!.dropFirst(16)
            SSCP = String(b.dropFirst(8) + c.dropFirst(8))
            print("LIB >>>> SSC : " + SSCP)
      
            // MARK: - Step 15 : Calculate KSseed by XOR Kic with Kifd
            let SKseed = util?.XOR(Data1: String(Kic), Data2: Kifd!)
      
            // MARK: - Step 16 : Calculate KSenc and KSmac from SKeed
            let SKey = util?.CalculateKey(Kseed: SKseed!)
            SKenc = SKey![0]!
            SKmac = SKey![1]!
            print("LIB >>>> SKenc : " + SKenc)
            print("LIB >>>> SKmac : " + SKmac)
      
            print("""
            
            #####################################
              END EXTERNAL AUTHENTICATION STEP 
            #####################################
            
            """)
            return true
        }else{
            print("LIB >>>> Fail To Begin Card Session")
            return false
        }
        
    }
    
    func readDG1() async {

        print("""
        
        #####################################
              BEGIN READ DATA GROUP 1 
        #####################################
        
        """)
        
        // MARK: - Step 1 : Consruct APDU Cmd for SELECT DG1
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = self.ConstructAPDUforSelectDF(DG:DG.DG1.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG1) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG1) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify Res Apdu select DG1
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Read Binary for get length DG data
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "04", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD GET LEN DG1) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES GET LEN DG1) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res Apdu get len DG1
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                
                // MARK: - Step 5 : Get Len of DG1 from Response
                let len = CalculateLenDG1(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG1 Len : " + len)
                
                
                // MARK: - Step 6 : Construct APDU For Read DG1 Data
                SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                apdu = self.ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "05", HexLength:len , SSC: SSCP, SKmac: SKmac)
                print("LIB >>>> (APDU CMD READ DG1) >>>> : " + apdu)
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                print("LIB <<<< (APDU RES READ DG1) <<<< : " + res.uppercased())
                
                //MARK: - Step 7 : Verify RES APDU Read Data DG1
                SSCP = (self.util?.IncrementHex(Hex:SSCP, Increment: 1))!
                verify = self.VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                if verify {
                    let data = GetDataDG1(APDU: res, SKenc: SKenc)
                    print("LIB >>>> DG1 : " + data)
                    model?.DG1 = data
                    model?.documentCode = String(data.prefix(2))
                    var data2 = data.dropFirst(2)
                    model?.issueState = String(data2.prefix(3))
                    data2 = data2.dropFirst(3)
                    model?.holderFullName = String(data2.prefix(31))
                    let splitname = model?.holderFullName?.split(separator: "<", omittingEmptySubsequences: false)
                    print(splitname!)
                    model?.holderMiddleName = String((splitname?[1])!)
                    model?.holderLastName = String((splitname?[0])!)
                    if splitname![3] != "" {
                        model?.holderFirstName = String(splitname![2] + " " + splitname![3])
                    }else{
                        model?.holderFirstName = String((splitname?[2])!)
                    }
                    data2 = data2.dropFirst(39)
                    model?.documentNumber = String(data2.prefix(9))
                    data2 = data2.dropFirst(9)
                    model?.docNumCheckDigit = String(data2.prefix(1))
                    data2 = data2.dropFirst(1)
                    model?.nationality = String(data2.prefix(3))
                    data2 = data2.dropFirst(3)
                    model?.dateOfBirth = String(data2.prefix(6))
                    data2 = data2.dropFirst(6)
                    model?.dateOfBirthCheckDigit = String(data2.prefix(1))
                    data2 = data2.dropFirst(1)
                    model?.sex = String(data2.prefix(1))
                    data2 = data2.dropFirst(1)
                    model?.dateOfExpiry = String(data2.prefix(6))
                    data2 = data2.dropFirst(6)
                    model?.dateOfExpiryCheckDigit = String(data.prefix(1))
                    data2 = data2.dropFirst(1)
                    model?.optionalData = String(data2.dropLast(3))
                    
                }else{
                    print("LIB >>>> Verify RES APDU READ DG1 Fail")
                } // end of verify cc read dg1
                
            }else{
                print("LIB >>>> Verify RES APDU GET LEN DG1 Fail")
            } // end of verify get dg1 len
        }else{
            print("LIB >>>> Verify RES APDU SELECT DG1 Fail")
        } // end of verify select dg1
        
        print("""
        
        #####################################
                END READ DATA GROUP 1 
        #####################################
        
        """)
    }
    
    func readDG2() async {
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 2 
        #####################################
        
        """)

        // MARK: - Step 1 : Consruct APDU for SELECT DG2
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = ConstructAPDUforSelectDF(DG:DG.DG2.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG2) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG2) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify RES APDU Select DG2
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Get Len DG2
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "30", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD GET LEN DG2) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES GET LEN DG2) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res APDU Get Len DG2
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                let len = CalculateLenDG2(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG2 LEN : " + len[0])
                print("LIB >>>> DG2 OFFSET : " + len[1])
                
                // MARK: - Step 5 : Get All Data DG2
                SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
                apdu = ConstructAPDUforReadBinaryExtend(HexBlock: "00", HexOffset: len[1], HexLength: len[0], SSC: SSCP, SKmac: SKmac)
                print("LIB >>>> (APDU CMD READ DG2) >>>> : " + apdu)
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                print("LIB <<<< (APDU RES READ DG2) <<<< : " + res.uppercased())
                
                // MARK: - Step 6 : Verify Res Apdu Read DG2
                SSCP = (util?.IncrementHex(Hex:SSCP, Increment: 1))!
                verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                if verify {
                    let r = GetDataDG2(APDU: res, SKenc: SKenc)
                    let allLen = (UInt32(len[0],radix: 16)! * 2) - 1000
                    print(allLen)
                    if r.count < allLen {
                        
                        print("Still Remain!!!")
                        var re:String = ""
                        // MARK: - Step 7 : Get Remain Data DG2
                        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
                        apdu = ConstructAPDUforReadBinaryExtend(HexBlock: "00", HexOffset:"00", HexLength: "FFFF", SSC: SSCP, SKmac: SKmac)
                        print("LIB >>>> (APDU CMD READ DG2) >>>> : " + apdu)
                        res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                        print("LIB <<<< (APDU RES READ DG2) <<<< : " + res.uppercased())

                        // MARK: - Step 6 : Verify Res Apdu Read DG2
                        SSCP = (util?.IncrementHex(Hex:SSCP, Increment: 1))!
                        verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                        if verify {
                            let r2 = GetRemainDataDG2(APDU: res, SKenc: SKenc)
                            re.append(r2)
                        }else{
                            print("LIB >>>> Verify RES APDU READ REMAIN DG2 Fail")
                        } // end of verify res apdu read ramin dg2
                        
                        // Loop for get all remain data
                        while re.count < allLen {
                            
                            // MARK: - Step 7 : Get Remain Data DG2
                            let new = re.count/2
                            var newOffset = String(new,radix: 16)
                            while newOffset.count < 4 {
                                newOffset = "0" + newOffset
                            }
                            print(newOffset)
                            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
                            apdu = ConstructAPDUforReadBinaryExtend(HexBlock: String(newOffset.dropLast(2)), HexOffset: String(newOffset.dropFirst(2)), HexLength: len[0], SSC: SSCP, SKmac: SKmac)
                            print("LIB >>>> (APDU CMD READ DG2) >>>> : " + apdu)
                            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                            print("LIB <<<< (APDU RES READ DG2) <<<< : " + res.uppercased())
                            
                            // MARK: - Step 6 : Verify Res Apdu Read DG2
                            SSCP = (util?.IncrementHex(Hex:SSCP, Increment: 1))!
                            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                            if verify {
                                let r2 = GetRemainDataDG2(APDU: res, SKenc: SKenc)
                                re.append(r2)
                            }else{
                                print("LIB >>>> Verify RES APDU READ REMAIN DG2 Fail")
                                break
                            } // end of verify res apdu read ramin dg2
                        }
                        let re1 = String(re.dropFirst(170))
                        let djpg = UIImage(data: re1.hexadecimal!)!.jpegData(compressionQuality: 1.0)
                        model?.faceImage = djpg?.base64EncodedString()
                        
                    }else{
                        let djpg = UIImage(data: r.hexadecimal!)!.jpegData(compressionQuality: 1.0)
                        model?.faceImage = djpg?.base64EncodedString()
                    } // end of get dg2 data
                    
                }else{
                    print("LIB >>>> Verify RES APDU READ DG2 Fail")
                } // end of verify res apdu read dg2
                
            }else{
                print("LIB >>>> Verify RES APDU GET LEN DG2 Fail")
            } // end of verify res apdu get len dg2

        }else{
            print("LIB >>>> Verify RES APDU SELECT DG2 Fail")
        } // end of verify res apdu select dg2
        
        print("""
        
        #####################################
               END READ DATA GROUP 2 
        #####################################
        
        """)

    }
    
    func readDG3() async {
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 3 
        #####################################
        
        """)

        // MARK: - Step 1 : Consruct APDU for SELECT DG3
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = ConstructAPDUforSelectDF(DG:DG.DG3.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG2) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG2) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify RES APDU Select DG3
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Get Len DG3
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "30", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD GET LEN DG2) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES GET LEN DG2) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res APDU Get Len DG3
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                let len = CalculateLenDG2(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG2 LEN : " + len[0])
                print("LIB >>>> DG2 OFFSET : " + len[1])
                
                // MARK: - Step 5 : Get All Data DG3
                SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
                apdu = ConstructAPDUforReadBinaryExtend(HexBlock: "00", HexOffset: len[1], HexLength: len[0], SSC: SSCP, SKmac: SKmac)
                print("LIB >>>> (APDU CMD READ DG3) >>>> : " + apdu)
                res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                print("LIB <<<< (APDU RES READ DG3) <<<< : " + res.uppercased())
                
                // MARK: - Step 6 : Verify Res Apdu Read DG3
                SSCP = (util?.IncrementHex(Hex:SSCP, Increment: 1))!
                verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                if verify {
                    let r = GetDataDG2(APDU: res, SKenc: SKenc)
                    let allLen = (UInt32(len[0],radix: 16)! * 2) - 1000
                    print(allLen)
                    if r.count < allLen {
                        
                        print("Still Remain!!!")
                        var re:String = ""
                        // MARK: - Step 7 : Get Remain Data DG3
                        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
                        apdu = ConstructAPDUforReadBinaryExtend(HexBlock: "00", HexOffset:"00", HexLength: "FFFF", SSC: SSCP, SKmac: SKmac)
                        print("LIB >>>> (APDU CMD READ DG3) >>>> : " + apdu)
                        res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                        print("LIB <<<< (APDU RES READ DG3) <<<< : " + res.uppercased())

                        // MARK: - Step 6 : Verify Res Apdu Read DG3
                        SSCP = (util?.IncrementHex(Hex:SSCP, Increment: 1))!
                        verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                        if verify {
                            let r2 = GetRemainDataDG2(APDU: res, SKenc: SKenc)
                            re.append(r2)
                        }else{
                            print("LIB >>>> Verify RES APDU READ REMAIN DG3 Fail")
                        } // end of verify res apdu read ramin dg2
                        
                        // Loop for get all remain data
                        while re.count < allLen {
                            
                            // MARK: - Step 7 : Get Remain Data DG3
                            let new = re.count/2
                            var newOffset = String(new,radix: 16)
                            while newOffset.count < 4 {
                                newOffset = "0" + newOffset
                            }
                            print(newOffset)
                            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
                            apdu = ConstructAPDUforReadBinaryExtend(HexBlock: String(newOffset.dropLast(2)), HexOffset: String(newOffset.dropFirst(2)), HexLength: len[0], SSC: SSCP, SKmac: SKmac)
                            print("LIB >>>> (APDU CMD READ DG2) >>>> : " + apdu)
                            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
                            print("LIB <<<< (APDU RES READ DG2) <<<< : " + res.uppercased())
                            
                            // MARK: - Step 6 : Verify Res Apdu Read DG2
                            SSCP = (util?.IncrementHex(Hex:SSCP, Increment: 1))!
                            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
                            if verify {
                                let r2 = GetRemainDataDG2(APDU: res, SKenc: SKenc)
                                re.append(r2)
                            }else{
                                print("LIB >>>> Verify RES APDU READ REMAIN DG2 Fail")
                                break
                            } // end of verify res apdu read ramin dg3
                        }
                        let re1 = String(re.dropFirst(170))
                        let djpg = UIImage(data: re1.hexadecimal!)!.jpegData(compressionQuality: 1.0)
                        model?.faceImage = djpg?.base64EncodedString()
                        
                    }else{
                        let djpg = UIImage(data: r.hexadecimal!)!.jpegData(compressionQuality: 1.0)
                        model?.faceImage = djpg?.base64EncodedString()
                    } // end of get dg2 data
                    
                }else{
                    print("LIB >>>> Verify RES APDU READ DG3 Fail")
                } // end of verify res apdu read dg2
                
            }else{
                print("LIB >>>> Verify RES APDU GET LEN DG3 Fail")
            } // end of verify res apdu get len dg2

        }else{
            print("LIB >>>> Verify RES APDU SELECT DG3 Fail")
        } // end of verify res apdu select dg2
        
        print("""
        
        #####################################
               END READ DATA GROUP 3 
        #####################################
        
        """)

    }

    
    func readDG7() async {
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 7 
        #####################################
        
        """)
        
        // MARK: - Step 1 : Consruct APDU for SELECT DG7
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = ConstructAPDUforSelectDF(DG:DG.DG11.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG11) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG11) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify Res Apdu select DG11
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Read Binary for get length DG data
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "FF", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD GET LEN DG11) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES GET LEN DG11) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res Apdu get len DG11
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                
                // MARK: - Step 5 : Read DG11
                let dg11 = GetDataDG11(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG11 : " + dg11)
                
                // MARK: - Step 6 : Loop for each data
                model?.personalNumber = SplitDataDG11(dg11: dg11, Tag: "5F10")
                model?.fullDateOfBirth = SplitDataDG11(dg11: dg11, Tag: "5F2B")
                model?.placeOfBirth = SplitDataDG11(dg11: dg11, Tag: "5F11")
                model?.permanentAddress = SplitDataDG11(dg11: dg11, Tag: "5F42")
                model?.telephone = SplitDataDG11(dg11: dg11, Tag: "5F12")
                model?.profession = SplitDataDG11(dg11: dg11, Tag: "5F13")
                model?.title = SplitDataDG11(dg11: dg11, Tag: "5F14")
                model?.personelSummary = SplitDataDG11(dg11: dg11, Tag: "5F15")
     
                
            }else{
                print("LIB >>>> Verify RES APDU READ DG11 Fail")
            } // end of verify read dg11
        }else{
            print("LIB >>>> Verify RES APDU SELECT DG11 Fail")
        } // end of verify select dg1
        
        
        print("""
        
        #####################################
              End READ DATA GROUP 11 
        #####################################
        
        """)
        
    }
    
    func readDG11() async {
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 11 
        #####################################
        
        """)
        
        // MARK: - Step 1 : Consruct APDU for SELECT DG11
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = ConstructAPDUforSelectDF(DG:DG.DG11.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG11) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG11) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify Res Apdu select DG11
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Read Binary for get length DG data
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "FF", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD GET LEN DG11) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES GET LEN DG11) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res Apdu get len DG11
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                
                // MARK: - Step 5 : Read DG11
                let dg11 = GetDataDG11(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG11 : " + dg11)
                
                // MARK: - Step 6 : Loop for each data
                model?.personalNumber = SplitDataDG11(dg11: dg11, Tag: "5F10")
                model?.fullDateOfBirth = SplitDataDG11(dg11: dg11, Tag: "5F2B")
                model?.placeOfBirth = SplitDataDG11(dg11: dg11, Tag: "5F11")
                model?.permanentAddress = SplitDataDG11(dg11: dg11, Tag: "5F42")
                model?.telephone = SplitDataDG11(dg11: dg11, Tag: "5F12")
                model?.profession = SplitDataDG11(dg11: dg11, Tag: "5F13")
                model?.title = SplitDataDG11(dg11: dg11, Tag: "5F14")
                model?.personelSummary = SplitDataDG11(dg11: dg11, Tag: "5F15")
     
                
            }else{
                print("LIB >>>> Verify RES APDU READ DG11 Fail")
            } // end of verify read dg11
        }else{
            print("LIB >>>> Verify RES APDU SELECT DG11 Fail")
        } // end of verify select dg1
        
        
        print("""
        
        #####################################
              End READ DATA GROUP 11 
        #####################################
        
        """)
        
    }
    
    func readDG12() async {
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 12 
        #####################################
        
        """)
        
        // MARK: - Step 1 : Consruct APDU for SELECT DG12
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = ConstructAPDUforSelectDF(DG:DG.DG12.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG12) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG12) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify Res Apdu select DG12
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Read Binary for get length DG data
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "FF", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD READ DG12) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES READ DG12) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res Apdu get len DG12
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                
                // MARK: - Step 5 : Read DG12
                let dg12 = GetDataDG12(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG12 : " + dg12)

                
            }else{
                print("LIB >>>> Verify RES APDU READ DG12 Fail")
            } // end of verify read dg11
        }else{
            print("LIB >>>> Verify RES APDU SELECT DG12 Fail")
        } // end of verify select dg1
        
        print("""
        
        #####################################
              END READ DATA GROUP 12 
        #####################################
        
        """)
        
    }
    
    func readDG15() async {
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 15
        #####################################
        
        """)
        
        // MARK: - Step 1 : Consruct APDU for SELECT DG15
        SSCP = (util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
        var apdu = ConstructAPDUforSelectDF(DG:DG.DG15.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
        print("LIB >>>> (APDU CMD SELECT DG15) >>>> : " + apdu)
        var res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
        print("LIB <<<< (APDU RES SELECT DG15) <<<< : " + res.uppercased())
        
        // MARK: - Step 2 : Verify Res Apdu select DG15
        SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
        var verify = VerifySelectRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
        if verify {
            
            // MARK: - Step 3 : Send APDU Read Binary for get length DG data
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            apdu = ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "FF", SSC: SSCP, SKmac: SKmac)
            print("LIB >>>> (APDU CMD READ DG15) >>>> : " + apdu)
            res = await rmngr.transmitCardAPDU(card: rmngr.card!, apdu: apdu)
            print("LIB <<<< (APDU RES READ DG15) <<<< : " + res.uppercased())
            
            // MARK: - Step 4 : Verify Res Apdu get len DG12
            SSCP = (util?.IncrementHex(Hex: SSCP, Increment: 1))!
            verify = VerifyReadBinaryRAPDU(APDU: res, SSC: SSCP, Key: SKmac)
            if verify {
                
                // MARK: - Step 5 : Read DG12
                let dg15 = GetDataDG15(APDU:res, SKenc: SKenc)
                print("LIB >>>> DG15 : " + dg15)

                
            }else{
                print("LIB >>>> Verify RES APDU READ DG15 Fail")
            } // end of verify read dg11
        }else{
            print("LIB >>>> Verify RES APDU SELECT DG15 Fail")
        } // end of verify select dg1
        
        print("""
        
        #####################################
              END READ DATA GROUP 15 
        #####################################
        
        """)
        
    }
    
    func ReadRFIDData(mrz:String,dg1:Bool,dg2:Bool,dg3:Bool,dg7:Bool,dg11:Bool,dg12:Bool,dg15:Bool) {
        
        // Plus for external authen
        eachProgress += 1.0
        
        if dg1 {
            eachProgress += 1.0
        }
        
        if dg2 {
            eachProgress += 1.0
        }
        
        if dg3 {
            eachProgress += 1.0
        }
        
        if dg11 {
            eachProgress += 1.0
        }
        
        if dg12 {
            eachProgress += 1.0
        }
        
        if dg15 {
            eachProgress += 1.0
        }
        
        eachProgress = 1.0 / eachProgress
        
        
        Task.init{
            
            let isSuccess = await externalAuthnetication(mrz: mrz)
            progress += eachProgress
            delegate?.onProgressReadPassportData(progress: progress)
            
            if dg1 && isSuccess {
                await readDG1()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            if dg2 && isSuccess {
                await readDG2()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            if dg3 && isSuccess {
                await readDG3()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            if dg7 && isSuccess {
                await readDG7()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            if dg11 && isSuccess {
                await readDG11()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            if dg12 && isSuccess {
                await readDG12()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            if dg15 && isSuccess {
                await readDG15()
                progress += eachProgress
                delegate?.onProgressReadPassportData(progress: progress)
            }
            
            delegate?.onCompleteReadPassportData(data: model!)
            rmngr.endCardSession()
        }
        
    }
}
            

                                            
