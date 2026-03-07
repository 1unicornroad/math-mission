//
//  FontHelper.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit

extension UIFont {
    
    // Orbitron fonts (space-themed, futuristic)
    static func orbitronBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Orbitron-Bold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    
    static func orbitronMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "Orbitron-Medium", size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
    static func orbitronRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "Orbitron-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    // Exo 2 fonts (readable, tech-inspired)
    static func exo2Bold(size: CGFloat) -> UIFont {
        return UIFont(name: "Exo2-Bold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    
    static func exo2SemiBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Exo2-SemiBold", size: size) ?? UIFont.systemFont(ofSize: size, weight: .semibold)
    }
    
    static func exo2Regular(size: CGFloat) -> UIFont {
        return UIFont(name: "Exo2-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func exo2Medium(size: CGFloat) -> UIFont {
        return UIFont(name: "Exo2-Medium", size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
}
