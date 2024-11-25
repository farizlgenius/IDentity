//
//  ThaiIdController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 25/11/2567 BE.
//

import Foundation

class ThaiIdController
{
    // APDU Command
    enum apdu:String {
        case chipId = "80CA9F7F2D"
        case laserId = "00A4040008A000000084060002"
        case getLaserId = "8000000017"
        case selectThaiIdDf = "00A4040008A000000054480001"
    }
    
    init(){}
    
}
