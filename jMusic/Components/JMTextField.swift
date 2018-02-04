//
//  JMTextField.swift
//  jMusic
//
//  Created by Jota Melo on 31/07/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import UIKit

class JMTextField: UITextField {

    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
            self.layer.masksToBounds = true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.commonInit()
    }
    
    private func commonInit() {
        
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        self.leftViewMode = .always
    }

}
