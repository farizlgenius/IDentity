//
//  PassportCaptureViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 1/12/2567 BE.
//

import Foundation
import AVFoundation
import UIKit
import QKMRZScanner

class PassportCaptureViewController:UIViewController,QKMRZScannerViewDelegate {
    @IBOutlet weak var mrzScannerView: QKMRZScannerView!
    var ocrResult:QKMRZScanResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mrzScannerView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mrzScannerView.startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mrzScannerView.stopScanning()
    }

    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
        ocrResult = scanResult
        print(scanResult.documentNumber)
        performSegue(withIdentifier: "scanMRZFinish", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scanMRZFinish" {
            let controller = segue.destination as! ReadPassportViewController
            controller.ocrResult = ocrResult
        }
    }
    

}


