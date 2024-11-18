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
    
    //Passport Data
    var DG1:String?
    var DG2:String?
    
    // APDU Command
    let SELECTDFSTR:String = "00A4040007A0000002471001"
    let GETCHALLENGESTR:String = "0084000008"
    
    // properties
    let mngr:TKSmartCardSlotManager?
    let util:Utility?
    var model:PassportDataModel?
    
    // Constructor
    init(){
        mngr = TKSmartCardSlotManager.default
        util = Utility()
        model = PassportDataModel()
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
            print("LIB MSG >>>> Verify Select APDU Command Success")
            return true
        }else{
            print("LIB MSG >>>> Verify Select APDU Command Unsuccess")
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
        let DropIndex = RAPDU.count - (self.util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!
        let K = SSC + RAPDU.dropLast(DropIndex) + "80"
        let CC = self.util?.MessageAuthenticationCodeMethodOne(input: K, key: Key)
        let DO8E = RAPDU.dropFirst((self.util?.FindIndexOf(inputString: String(RAPDU), target: "8E08"))!+4)
        if CC! == DO8E {
            print("LIB MSG >>>> Verify Read Binart APDU Command Success")
            return true
        }else{
            print("LIB MSG >>>> Verify Read Binart APDU Command Unsuccess")
            return false
        }
    }
    
    func GetLengthDG1(APDU:String,SKenc:String)->String{
        var result = APDU.dropFirst(6)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(2))!
        let index = result.count - (util?.FindIndexOf(inputString: String(result), target: "5F1F"))!
        let length = result.dropLast(index)
        print("LIB MSG >>>> Data Len : " + length)
        return String(length)
    }
    
    func GetLengthDG2(APDU:String,SKenc:String)->[String]{
        var result = APDU.dropFirst(6)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
        print("result 1 : " + result)
        let encResult = util?.TripleDesDecCBC(input: String(result), key: SKenc)
        print("result 2 : " + encResult!)
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
        print("result 1 : " + result)
        result = (util?.TripleDesDecCBC(input: String(result), key: SKenc).dropFirst(4))!
        print("result 2 : " + result)
        result = result.dropFirst(88).dropLast(6)
        return String(result)
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
    
    func response(re:Data?,error:Error?){
        
    }
    
    
    func startReadDGData(mrz:String){
        
        // MARK: - Step 1 : Hash MRZ Data with SHA1 Algorithm
        let mrzData = mrz.data(using: .utf8)
        let Kseed = util?.sha1HashData(data: mrzData!).prefix(32)
        print("LIB MSG >>>> Kseed : " + Kseed!)
        
        // MARK: - Step 2 / 3 : Calculate Kenc and Kmac from Kseed and adjust Parity
        let Key1 = util?.CalculateKey(Kseed: String(Kseed!))
        let Kenc = Key1![0]
        let Kmac = Key1![1]
        
        print("LIB MSG >>>> Kenc : " + Kenc!)
        print("LIB MSG >>>> Kmac : " + Kmac!)
        
        // MARK: - Step 4 : Initial SmartCard
        var slotName:String = ""
        if mngr?.slotNames[0] != nil {
            slotName = mngr?.slotNames[0] ?? "nil"
        }
        print("LIB MSG >>>> Slot Name : " + slotName)
        mngr?.getSlot(withName: slotName){
            (slot:TKSmartCardSlot?) in
            let card = slot?.makeSmartCard()
            card?.useExtendedLength = true
            if card != nil {
                card!.beginSession{
                    (success:Bool,error:Error?) in
                    if success {
                        
                        // Global Variable for Call Command
                        var SKenc:String = ""
                        var SKmac:String = ""
                        var SSCP:String = ""
                        
                        // MARK: - Step 5 : Transmit APDU for SELECT DF of Passport
                        print("LIB MSG (APDU CMD) >>>> : " + self.SELECTDFSTR)
                        var data = NSData(bytes: self.SELECTDFSTR.hexaBytes, length: self.SELECTDFSTR.hexaData.count)
                        card?.transmit(data as Data)
                        {
                            (re:Data?,error:Error?) in
                            if error != nil {
                                print("LIB MSG >>>> Transmit APDU Error : ",error!)
                            }else
                            {
                                var res = re?.hexadecimal
                                print("LIB MSG (Response) <<<< : " + res!)
                                
                                // MARK: - Step 6 : Transmit Get Challenge APDU
                                print("LIB MSG (APDU CMD) >>>> : " + self.GETCHALLENGESTR)
                                data = NSData(bytes: self.GETCHALLENGESTR.hexaBytes, length: self.GETCHALLENGESTR.hexaData.count)
                                card?.transmit(data as Data){
                                    (re:Data?,error:Error?) in
                                    if error != nil {
                                        print("LIB MSG >>>> Transmit APDU Error : ",error!)
                                    }else
                                    {
                                        res = re?.hexadecimal
                                        print("LIB MSG (Response) <<<< : " + res!)
                                        
                                        let RNDIC = res!.dropLast(4)
                                        
                                        // MARK: - Step 7 : Generate random 8 byte hex and 16 byte hex
                                        let Kifd = self.util?.RandomHex(numDigit: 32)
                                        let RNDIFD = self.util?.RandomHex(numDigit: 16)
                                        
                                        // MARK: - Step 8 : Get S by concatenate RNDIFD + RNDIC + Kifd
                                        let S = RNDIFD! + RNDIC + Kifd!
                                        print("LIB MSG >>>> S : " + S)
                                        
                                        // MARK: - Step 9 : Get Eifd by Encrypt S with Kenc by 3DES CBC Algorithm
                                        let Eifd = self.util?.TripleDesEncCBC(input: S, key: Kenc!)
                                        print("LIB MSG >>>> Eifd : " + Eifd!)
                                        
                                        // MARK: - Step 10 : Get Mifd by Calculate Message Authentication Code Padding Method 2 over Eifd by Kmac
                                        let Mifd = self.util?.MessageAuthenticationCodeMethodTwo(input: Eifd!, key: Kmac!)
                                        print("LIB MSG >>>> Mifd : " + Mifd!)
                                        
                                        // MARK: Step 11 : Construct APDU Cmd for do External Authentication Cmd = Eifd concatinate with Mifd
                                        let cmdAPDU = "0082000028" + Eifd! + Mifd! + "28"
                                        
                                        // MARK: - Step 12 : Send APDU command
                                        print("LIB MSG (APDU CMD) >>>> : " + cmdAPDU)
                                        data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                        card?.transmit(data as Data)
                                        {
                                            (re:Data?,error:Error?) in
                                            if error != nil {
                                                print("LIB MSG >>>> Transmit APDU Error : ",error!)
                                            }else{
                                                res = re?.hexadecimal
                                                print("LIB MSG (Response) <<<< : " + res!)
                                                
                                                //MARK: - Step 13 : Get Eic by Cut Off Mic from response and decrypt Eic to get R
                                                let Eic = res?.dropLast(20)
                                                print("LIB MSG >>>> Eic : " + Eic!)
                                                let R = self.util?.TripleDesDecCBC(input: String(Eic!), key: Kenc!)
                                                print("LIB MSG >>>> R : " + R!)
                                                
                                                //MARK: - Step 14 : Get Kic and SSC from R
                                                let Kic = R!.dropFirst(32)
                                                print("LIB MSG >>>> Kic : " + Kic)
                                                let a = R?.dropLast(32)
                                                let b = a!.dropLast(16)
                                                let c = a!.dropFirst(16)
                                                SSCP = String(b.dropFirst(8) + c.dropFirst(8))
                                                print("LIB MSG >>>> SSC : " + SSCP)
                                                
                                                // MARK: - Step 15 : Calculate KSseed by XOR Kic with Kifd
                                                let SKseed = self.util?.XOR(Data1: String(Kic), Data2: Kifd!)
                                                
                                                // MARK: - Step 16 : Calculate KSenc and KSmac from SKeed
                                                let SKey = self.util?.CalculateKey(Kseed: SKseed!)
                                                SKenc = SKey![0]!
                                                SKmac = SKey![1]!
                                                print("LIB MSG >>>> SKenc : " + SKenc)
                                                print("LIB MSG >>>> SKmac : " + SKmac)
                                                
                                                /*#####################################
                                                 END OF EXTERNAL AUTHNETICATION STEP
                                                 #####################################*/
                                                
                                                
                                                /*############################
                                                 BEGIN OF READING DG 1 STEP
                                                 ############################*/
                                                
                                                // MARK: - Step 17 : Consruct APDU Cmd for SELECT DG1
                                                SSCP = (self.util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
                                                var cmdAPDU = self.ConstructAPDUforSelectDF(DG:DG.DG1.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
                                                print("LIB MSG (APDU CMD) Select DG1 >>>> : " + cmdAPDU)
                                                data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                                card?.transmit(data as Data)
                                                {
                                                    (re:Data?,error:Error?) in
                                                    if error != nil {
                                                        print("LIB MSG >>>> Transmit APDU Error : ",error!)
                                                    }else
                                                    {
                                                        res = re?.hexadecimal
                                                        print("LIB MSG (Response) Select DG1 <<<< : " + res!)
                                                        SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                        var verify = self.VerifySelectRAPDU(APDU: res!, SSC: SSCP, Key: SKmac)
                                                        if verify {
                                                            
                                                            // MARK: - Step 20 : Send APDU Read Binary for get length DG data
                                                            SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                            cmdAPDU = self.ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "04", SSC: SSCP, SKmac: SKmac)
                                                            print("LIB MSG (APDU CMD) GET DG1 Len >>>> : " + cmdAPDU)
                                                            data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                                            card?.transmit(data as Data)
                                                            {
                                                                (re:Data?,error:Error?) in
                                                                if error != nil
                                                                {
                                                                    print("LIB MSG >>>> Transmit APDU Get DG1 Len Error : ",error!)
                                                                }else
                                                                {
                                                                    res = re?.hexadecimal
                                                                    print("LIB MSG (Response) RES DG1 Len <<<< : " + res!)
                                                                    SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                                    verify = self.VerifyReadBinaryRAPDU(APDU: res!, SSC: SSCP, Key: SKmac)
                                                                    if verify {
                                                                        
                                                                        // MARK: - Step 21 : Get Length of DG from Response
                                                                        let len = self.GetLengthDG1(APDU:res!, SKenc: SKenc)
                                                                        print("LIB MSG >>>> DG1 Data Len : " + len)
                                                                        
                                                                        // MARK: - Step 22 : Construct APDU For Get DG1 Data
                                                                        SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                                        cmdAPDU = self.ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "05", HexLength:len , SSC: SSCP, SKmac: SKmac)
                                                                        data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                                                        card?.transmit(data as Data)
                                                                        {
                                                                            (re:Data?,error:Error?) in
                                                                            if error != nil
                                                                            {
                                                                                print("LIB MSG >>>> Transmit APDU Get DG1 Data Error : ",error!)
                                                                            }else
                                                                            {
                                                                                //MARK: - Step 23 : Verify CC of response APDU
                                                                                res = re?.hexadecimal
                                                                                print("LIB MSG (Response) Get DG1 Data <<<< : " + res!)
                                                                                SSCP = (self.util?.IncrementHex(Hex:SSCP, Increment: 1))!
                                                                                verify = self.VerifyReadBinaryRAPDU(APDU: res!, SSC: SSCP, Key: SKmac)
                                                                                if verify {
                                                                                    print("DG1 : " + self.GetData(APDU: res!, SKenc: SKenc) + "\n")
                                                                                    self.model?.DG1 = self.GetData(APDU: res!, SKenc: SKenc)
                                                                                }
                                                                                
                                                                                /*############################
                                                                                 BEGIN OF READING DG 2 STEP
                                                                                 ############################*/
                                                                                
                                                                                // MARK: Step 24 : Consruct APDU Cmd for SELECT DG2
                                                                                SSCP = (self.util?.IncrementHex(Hex: String(SSCP), Increment: 1))!
                                                                                var cmdAPDU = self.ConstructAPDUforSelectDF(DG:DG.DG2.rawValue,SKenc: SKenc,SKmac: SKmac,SSCP: SSCP)
                                                                                print("LIB MSG (APDU CMD) Select DG2 >>>> : " + cmdAPDU)
                                                                                data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                                                                card?.transmit(data as Data)
                                                                                {
                                                                                    (re:Data?,error:Error?) in
                                                                                    if error != nil {
                                                                                        print("LIB MSG >>>> Transmit APDU Error : ",error!)
                                                                                    }else
                                                                                    {
                                                                                        res = re?.hexadecimal
                                                                                        print("LIB MSG (Response) Select DG2 <<<< : " + res!)
                                                                                        SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                                                        let verify = self.VerifySelectRAPDU(APDU: res!, SSC: SSCP, Key: SKmac)
                                                                                        if verify
                                                                                        {
                                                                                            
                                                                                            // MARK: - Step 25 : Send APDU Read Binary for get length DG2 data
                                                                                            SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                                                            cmdAPDU = self.ConstructAPDUforReadBinary(HexBlock: "00", HexOffset: "00", HexLength: "30", SSC: SSCP, SKmac: SKmac)
                                                                                            print("LIB MSG (APDU CMD) Get DG2 Len >>>> : " + cmdAPDU)
                                                                                            data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                                                                            card?.transmit(data as Data)
                                                                                            {
                                                                                                (re:Data?,error:Error?) in
                                                                                                if error != nil {
                                                                                                    print("LIB MSG >>>> Transmit APDU Error : ",error!)
                                                                                                }else
                                                                                                {
                                                                                                    // MARK: Step 21 : Get Length of DG from Response
                                                                                                    res = re?.hexadecimal
                                                                                                    print("LIB MSG (Response) Get DG2 Len <<<< : " + res!)
                                                                                                    
                                                                                                    // MARK: - Step 22 : Verify CC from APDU
                                                                                                    /**/
                                                                                                    SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                                                                    let len = self.GetLengthDG2(APDU:res!, SKenc: SKenc)
                                                                                                    
                                                                                                    // MARK: - Step 23 : Get All Data DG2
                                                                                                    SSCP = (self.util?.IncrementHex(Hex: SSCP, Increment: 1))!
                                                                                                    cmdAPDU = self.ConstructAPDUforReadBinaryExtend(HexBlock: "00", HexOffset: len[1], HexLength: len[0], SSC: SSCP, SKmac: SKmac)
                                                                                                    print("LIB MSG (APDU CMD) >>>> : " + cmdAPDU)
                                                                                                    data = NSData(bytes: cmdAPDU.hexaBytes, length: cmdAPDU.hexaData.count)
                                                                                                    card?.transmit(data as Data)
                                                                                                    {
                                                                                                        (re:Data?,error:Error?) in
                                                                                                        if error != nil {
                                                                                                            print("LIB MSG >>>> Transmit APDU Error : ",error!)
                                                                                                        }else
                                                                                                        {
                                                                                                            res = re?.hexadecimal
                                                                                                            print("LIB MSG (Response) <<<< : " + res!)
                                                                                                            let r = self.GetDataDG2(APDU: res!, SKenc: SKenc)
                                                                                                            print(r)
                                                                                                            self.model?.DG2 = r.hexadecimal
                                                                                                            
                                                                                                        }
                                                                                                        
                                                                                                    }
                                                                                                   
                                                                                                }
                                                                                            }
                                                                                            
                                                                                        }

                                                                                    }
                                                                                }
                                                                                
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }else{
                        print("LIB MSG >>>> Begin Session Unsuccess : ",error!)
                    }
                }
            }
        }
        
    }
}
            

                                            
