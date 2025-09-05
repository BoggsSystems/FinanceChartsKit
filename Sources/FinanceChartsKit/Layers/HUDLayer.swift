import Foundation
import QuartzCore
import UIKit

final class HUDLayer: CALayer {
    private let tickerLabel = CATextLayer()
    private let priceLabel = CATextLayer()
    private let percentLabel = CATextLayer()
    private let timeframeLabel = CATextLayer()
    private let statusLabel = CATextLayer()
    
    private var theme: Theme = .dark
    
    override init() {
        super.init()
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        addSublayer(tickerLabel)
        addSublayer(priceLabel)
        addSublayer(percentLabel)
        addSublayer(timeframeLabel)
        addSublayer(statusLabel)
        
        setupTextLayer(tickerLabel, fontSize: theme.primaryFontSize)
        setupTextLayer(priceLabel, fontSize: theme.primaryFontSize)
        setupTextLayer(percentLabel, fontSize: theme.secondaryFontSize)
        setupTextLayer(timeframeLabel, fontSize: theme.labelFontSize)
        setupTextLayer(statusLabel, fontSize: theme.labelFontSize)
        
        timeframeLabel.alignmentMode = .right
        statusLabel.alignmentMode = .right
        percentLabel.alignmentMode = .left
    }
    
    private func setupTextLayer(_ layer: CATextLayer, fontSize: CGFloat) {
        layer.fontSize = fontSize
        layer.foregroundColor = theme.textColor.cgColor
        layer.alignmentMode = .left
        layer.contentsScale = UIScreen.main.scale
        layer.isWrapped = false
    }
    
    func configure(symbol: String, price: CGFloat, percentChange: CGFloat, timeframe: Timeframe, theme: Theme, isConnected: Bool = true) {
        self.theme = theme
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        tickerLabel.string = symbol.uppercased()
        priceLabel.string = String(format: "%.2f", price)
        
        let percentText = String(format: "%+.2f%%", percentChange)
        percentLabel.string = percentText
        percentLabel.foregroundColor = percentChange >= 0 ? theme.upColor.cgColor : theme.downColor.cgColor
        
        timeframeLabel.string = timeframe.shortDisplayName
        
        if isConnected {
            statusLabel.string = "LIVE"
            statusLabel.foregroundColor = theme.upColor.cgColor
        } else {
            statusLabel.string = "RECONNECTING..."
            statusLabel.foregroundColor = theme.gridColor.cgColor
        }
        
        updateTheme()
        layoutLabels()
        
        CATransaction.commit()
    }
    
    private func updateTheme() {
        tickerLabel.foregroundColor = theme.textColor.cgColor
        priceLabel.foregroundColor = theme.textColor.cgColor
        timeframeLabel.foregroundColor = theme.textColor.cgColor
    }
    
    private func layoutLabels() {
        let bounds = self.bounds
        let margin: CGFloat = 20
        let spacing: CGFloat = 10
        
        tickerLabel.frame = CGRect(
            x: margin,
            y: margin,
            width: 100,
            height: 30
        )
        
        priceLabel.frame = CGRect(
            x: tickerLabel.frame.maxX + spacing,
            y: margin,
            width: 120,
            height: 30
        )
        
        percentLabel.frame = CGRect(
            x: priceLabel.frame.maxX + spacing,
            y: margin + 2,
            width: 80,
            height: 26
        )
        
        timeframeLabel.frame = CGRect(
            x: bounds.width - 80 - margin,
            y: margin,
            width: 80,
            height: 20
        )
        
        statusLabel.frame = CGRect(
            x: bounds.width - 120 - margin,
            y: margin + 30,
            width: 120,
            height: 20
        )
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        layoutLabels()
    }
}