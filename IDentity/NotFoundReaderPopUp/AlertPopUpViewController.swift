//
//  NotFoundReaderPopUpViewController.swift
//  PassportLib
//
//  Created by Far-iz Lengha on 26/11/2567 BE.
//

import UIKit

class AlertPopUpViewController: UIViewController {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var errorMessage:String?
    
    init(message:String){
        super.init(nibName: "AlertPopUpViewController", bundle: nil)
        DispatchQueue.main.async {
            self.modalPresentationStyle = .overFullScreen
        }
        errorMessage = message
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configView()
        label.text = errorMessage
    }

    @IBAction func pressOK(_ sender: UIButton) {
        hide()
    }
    
    func configView(){
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.contentView.alpha = 0
        self.contentView.layer.cornerRadius = 10
    }
    
    func appear(sender:UIViewController){
        DispatchQueue.main.async {
            sender.present(self, animated: false){
                self.show()
            }
        }
        
        
    }
    
    private func show(){
        UIView.animate(withDuration: 0.5, delay: 0.1){
            self.contentView.alpha = 1
            self.backView.alpha = 1
        }
        
    }
    
    func hide(){
        UIView.animate(withDuration: 0.5,delay: 0.0, options: .curveEaseOut){
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
            self.removeFromParent()
        }
    }
    

}
