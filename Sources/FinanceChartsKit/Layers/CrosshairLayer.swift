import Foundation
import QuartzCore
import UIKit

final class CrosshairLayer: CALayer {
    private let verticalLineLayer = CAShapeLayer()
    private let horizontalLineLayer = CAShapeLayer()
    private let calloutBackgroundLayer = CAShapeLayer()
    private let priceLabel = CATextLayer()
    private let timestampLabel = CATextLayer()
    private let rsiLabel = CATextLayer()
    
    private var candles: [Candle] = []
    private var theme: Theme = .dark
    private var crosshairX: CGFloat?
    private var showRSI = false
    private var rsiValues: [CGFloat?] = []
    
    override init() {
        super.init()
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        addSublayer(verticalLineLayer)
        addSublayer(horizontalLineLayer)
        addSublayer(calloutBackgroundLayer)
        addSublayer(priceLabel)
        addSublayer(timestampLabel)
        addSublayer(rsiLabel)
        
        verticalLineLayer.strokeColor = theme.crosshairColor.cgColor
        verticalLineLayer.lineWidth = 1.0
        verticalLineLayer.fillColor = UIColor.clear.cgColor
        
        horizontalLineLayer.strokeColor = theme.crosshairColor.cgColor
        horizontalLineLayer.lineWidth = 1.0
        horizontalLineLayer.fillColor = UIColor.clear.cgColor
        
        calloutBackgroundLayer.fillColor = theme.backgroundColor.withAlphaComponent(0.9).cgColor
        calloutBackgroundLayer.strokeColor = theme.gridColor.cgColor
        calloutBackgroundLayer.lineWidth = 1.0
        calloutBackgroundLayer.cornerRadius = 6.0
        
        setupTextLayers()
        
        isHidden = true
    }
    
    private func setupTextLayers() {
        let labels = [priceLabel, timestampLabel, rsiLabel]
        
        for label in labels {
            label.fontSize = theme.labelFontSize
            label.foregroundColor = theme.textColor.cgColor
            label.alignmentMode = .center
            label.contentsScale = UIScreen.main.scale
        }
    }
    
    func configure(candles: [Candle], theme: Theme, showRSI: Bool, rsiValues: [CGFloat?] = []) {
        self.candles = candles
        self.theme = theme
        self.showRSI = showRSI
        self.rsiValues = rsiValues
        
        updateTheme()
    }
    
    func setCrosshair(x: CGFloat?) {
        self.crosshairX = x
        
        if x == nil {
            isHidden = true
        } else {
            isHidden = false
            updateCrosshair()
        }
    }
    
    private func updateTheme() {
        verticalLineLayer.strokeColor = theme.crosshairColor.cgColor
        horizontalLineLayer.strokeColor = theme.crosshairColor.cgColor
        calloutBackgroundLayer.fillColor = theme.backgroundColor.withAlphaComponent(0.9).cgColor
        calloutBackgroundLayer.strokeColor = theme.gridColor.cgColor
        
        for label in [priceLabel, timestampLabel, rsiLabel] {
            label.foregroundColor = theme.textColor.cgColor
        }
    }
    
    private func updateCrosshair() {
        guard let x = crosshairX, !candles.isEmpty else { return }
        
        let bounds = self.bounds
        let spacing = bounds.width / CGFloat(candles.count)
        let candleIndex = Int(x / spacing)
        
        guard candleIndex >= 0 && candleIndex < candles.count else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let candle = candles[candleIndex]
        let candleX = CGFloat(candleIndex) * spacing + spacing / 2
        
        updateVerticalLine(at: candleX)
        updateHorizontalLine(for: candle)
        updateCallout(for: candle, at: candleX, index: candleIndex)
        
        CATransaction.commit()
    }
    
    private func updateVerticalLine(at x: CGFloat) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: bounds.height))
        verticalLineLayer.path = path
    }
    
    private func updateHorizontalLine(for candle: Candle) {
        let priceRange = getPriceRange()
        let y = bounds.height - ((candle.close - priceRange.min) / priceRange.range) * bounds.height * 0.7
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: bounds.width, y: y))
        horizontalLineLayer.path = path
    }
    
    private func updateCallout(for candle: Candle, at x: CGFloat, index: Int) {
        let priceText = String(format: "%.2f", candle.close)
        let timestampText = formatTimestamp(candle.timestamp)
        
        priceLabel.string = priceText
        timestampLabel.string = timestampText
        
        if showRSI && index < rsiValues.count, let rsi = rsiValues[index] {
            rsiLabel.string = String(format: "RSI: %.1f", rsi)
            rsiLabel.isHidden = false
        } else {
            rsiLabel.isHidden = true
        }
        
        let calloutWidth: CGFloat = 120
        let calloutHeight: CGFloat = showRSI ? 80 : 60
        let calloutX = min(max(x - calloutWidth / 2, 10), bounds.width - calloutWidth - 10)
        let calloutY: CGFloat = 10
        
        let calloutRect = CGRect(x: calloutX, y: calloutY, width: calloutWidth, height: calloutHeight)
        calloutBackgroundLayer.path = CGPath(roundedRect: calloutRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        
        priceLabel.frame = CGRect(x: calloutX, y: calloutY + 10, width: calloutWidth, height: 20)
        timestampLabel.frame = CGRect(x: calloutX, y: calloutY + 30, width: calloutWidth, height: 20)
        
        if showRSI {
            rsiLabel.frame = CGRect(x: calloutX, y: calloutY + 50, width: calloutWidth, height: 20)
        }
    }
    
    private func getPriceRange() -> (min: CGFloat, max: CGFloat, range: CGFloat) {
        guard !candles.isEmpty else { return (0, 1, 1) }
        
        let minPrice = candles.map(\.low).min() ?? 0
        let maxPrice = candles.map(\.high).max() ?? 1
        let range = maxPrice - minPrice
        let padding = range * 0.05
        
        return (
            min: minPrice - padding,
            max: maxPrice + padding,
            range: range + 2 * padding
        )
    }
    
    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd HH:mm"
        return formatter.string(from: date)
    }
}