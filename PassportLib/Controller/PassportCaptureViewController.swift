//
//  PassportCaptureViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 1/12/2567 BE.
//

import Foundation
import AVFoundation
import UIKit

class PassportCaptureViewController:UIViewController {
    
    var cropImage:UIImage?
    
    // Capture Session
    var session:AVCaptureSession?
    
    // Photo Output
    let output = AVCapturePhotoOutput()
    
    // Video Preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    // Shutter button
    private let shutterButton:UIButton = {
        let button = UIButton(frame: CGRect(x:0,y:0,width: 75,height: 50))
        button.setBackgroundImage(UIImage(systemName: "camera"), for: .normal)
        button.transform = button.transform.rotated(by: CGFloat(Double.pi/2))
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 10
        return button
    }()
    
    // Image Crop Overlay
    private let imgOverlay:UIImageView = {
        let imgOverlay = UIImageView(frame: CGRect(x:0,y:0,width: 150,height: 800))
        imgOverlay.layer.borderColor = UIColor.systemBlue.cgColor
        imgOverlay.layer.cornerRadius = 10
        imgOverlay.layer.borderWidth = 4
        return imgOverlay
    }()
    
    //Label
    private let labeText:UILabel = {
        let label = UILabel(frame: CGRect(x:0,y:0,width: 700,height: 100))
        label.text = "Place passport MRZ in square below"
        label.textColor = .blue
        label.font = .systemFont(ofSize: 40.0, weight: .bold)
        label.transform = label.transform.rotated(by: CGFloat(Double.pi/2))
        return label
    }()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        view.addSubview(imgOverlay)
        view.addSubview(labeText)
        checkCameraPermission()
        previewLayer.frame = view.bounds
        
        shutterButton.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shutterButton.center = CGPoint(x:view.frame.size.width/2+300,y:view.frame.size.height - 100)
        imgOverlay.center = CGPoint(x:view.frame.size.width/2,y:view.frame.size.height/2)
        labeText.center = CGPoint(x:view.frame.size.width/2+100,y:view.frame.size.height/2)
    }
    
    
    
    func checkCameraPermission(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // Request
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                DispatchQueue.global().async {
                    session.startRunning()
                }
                
                self.session = session
                
            }catch {
                print(error)
            }
        }
    }
    
    @objc private func didTapTakePhoto(){
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    func cropToBounds(image: UIImage) -> UIImage
    {
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        let contextSize: CGSize = contextImage.size
        let widthRatio = contextSize.height/UIScreen.main.bounds.size.width
        let heightRatio = contextSize.width/UIScreen.main.bounds.size.height

        let width = (self.imgOverlay.frame.size.height)*widthRatio
        let height = (self.imgOverlay.frame.size.width)*heightRatio
        let x = (contextSize.width/2) - width/2
        let y = (contextSize.height/2) - height/2
        let rect = CGRect(x: x, y: y, width: width , height: height)

        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        //let image: UIImage = UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation /*image.imageOrientation*/)
        let image:UIImage = UIImage(cgImage: imageRef)
        return image
    }

    
}

extension PassportCaptureViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        let image = UIImage(data: data)
        cropImage = cropToBounds(image: image!)
        
        DispatchQueue.global().async{
            self.session?.stopRunning()
        }
        
        
        self.performSegue(withIdentifier: "startTextRecog", sender: self)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startTextRecog" {
            let controller = segue.destination as! ReadPassportViewController
            controller.image = cropImage
        }
    }
}

