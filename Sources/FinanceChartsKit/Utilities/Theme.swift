import Foundation
import UIKit

public struct Theme {
    public let backgroundColor: UIColor
    public let gridColor: UIColor
    public let textColor: UIColor
    public let upColor: UIColor
    public let downColor: UIColor
    public let volumeColor: UIColor
    public let crosshairColor: UIColor
    public let overlayColors: [UIColor]
    public let indicatorColors: [UIColor]
    
    public let primaryFontSize: CGFloat
    public let secondaryFontSize: CGFloat
    public let labelFontSize: CGFloat
    
    public static let dark = Theme(
        backgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0),
        gridColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5),
        textColor: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
        upColor: UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0),
        downColor: UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0),
        volumeColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6),
        crosshairColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8),
        overlayColors: [
            UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),
            UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0),
            UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0)
        ],
        indicatorColors: [
            UIColor(red: 0.8, green: 0.4, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.8, green: 0.8, blue: 0.4, alpha: 1.0)
        ],
        primaryFontSize: 24,
        secondaryFontSize: 20,
        labelFontSize: 16
    )
    
    public static let deuteranopia = Theme(
        backgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0),
        gridColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5),
        textColor: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
        upColor: UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0),
        downColor: UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0),
        volumeColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6),
        crosshairColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8),
        overlayColors: [
            UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0),
            UIColor(red: 0.4, green: 0.0, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
        ],
        indicatorColors: [
            UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
        ],
        primaryFontSize: 24,
        secondaryFontSize: 20,
        labelFontSize: 16
    )
}