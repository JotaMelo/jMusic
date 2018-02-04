//
//  JMButton.swift
//  jMusic
//
//  Created by Jota Melo on 31/07/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import UIKit

@IBDesignable
class JMButton: UIButton {
    
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
}
