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
    
    // properties
    //let mngr:TKSmartCardSlotManager?
    //var card:TKSmartCard?
    let rmngr:ReaderController
    var isSmartCardInitialized:Bool?
    var isCardSessionBegin:Bool?
    let util:Utility?
    var model:PassportModel?
    var slotName:String = ""
    var SSCP = ""
    var SKmac = ""
    var SKenc = ""
    
    // Constructor
    init(rmngr:ReaderController){
        util = Utility()
        model = PassportModel()
        self.rmngr = rmngr
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
        print(RAPDU)
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
        //print("result 2 : " + encResult!)
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
    
    func GetDataDG1(APDU:String,SKenc:String)->String{
        let result = APDU.dropFirst(6).uppercased()
        let result2 = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "9902"))!)
        let result3 = util?.TripleDesDecCBC(input: String(result2), key: SKenc)
        print("LIB >>>> DG1 Hex : " + result3!.dropLast(16))
        return hexStringtoAscii(String(result3!.dropLast(16)))
    }
    
    func GetDataDG11(APDU:String,SKenc:String)->String{
        var data:[String]
        var result = APDU.dropFirst(6)
        result = result.dropLast(result.count - (self.util?.FindIndexOf(inputString: String(result), target: "99029000"))!)
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
        

        isSmartCardInitialized = await rmngr.initSmartCard()
        if isSmartCardInitialized! {
            isCardSessionBegin = await rmngr.beginCardSession()
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
                    var data = GetDataDG1(APDU: res, SKenc: SKenc)
                    print("LIB >>>> DG1 : " + data)
                    model?.DG1 = data
                    model?.documentCode = String(data.prefix(2))
                    var data2 = data.dropFirst(2)
                    model?.issueState = String(data2.prefix(3))
                    data2 = data2.dropFirst(3)
                    model?.holderFullName = String(data2.prefix(31))
                    let splitname = model?.holderFullName?.split(separator: "<", omittingEmptySubsequences: false)
                    print(splitname!)
                    model?.holderFirstName = String((splitname?[2])!).capitalized
                    model?.holderMiddleName = String((splitname?[1])!).capitalized
                    model?.holderLastName = String((splitname?[0])!).capitalized
                    data2 = data2.dropFirst(31)
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
                    model?.optionalData = String(data2.prefix(7))
                    
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
                    model?.DG2 = r.hexadecimal
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
    
    func readDG12(){
        
        print("""
        
        #####################################
              BEGIN READ DATA GROUP 12 
        #####################################
        
        """)
        
        print("""
        
        #####################################
              END READ DATA GROUP 12 
        #####################################
        
        """)
        
    }
    
    func ReadRFIDData(mrz:String,dg1:Bool,dg2:Bool,dg3:Bool,dg11:Bool) {
        
        Task.init{
            let isSuccess = await externalAuthnetication(mrz: mrz)
            if dg1 && isSuccess {
                await readDG1()
            }
            
            if dg2 && isSuccess {
                await readDG2()
            }
            
            if dg3 && isSuccess {
                
            }
            
            if dg11 && isSuccess {
                await readDG11()
            }
        }
        
    }
}
            

                                            
