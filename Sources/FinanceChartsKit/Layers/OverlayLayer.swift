import Foundation
import QuartzCore
import UIKit

final class OverlayLayer: CALayer {
    private let ema20Layer = CAShapeLayer()
    private let ema50Layer = CAShapeLayer()
    private let sma20Layer = CAShapeLayer()
    private let sma50Layer = CAShapeLayer()
    private let bollingerUpperLayer = CAShapeLayer()
    private let bollingerMiddleLayer = CAShapeLayer()
    private let bollingerLowerLayer = CAShapeLayer()
    
    private var candles: [Candle] = []
    private var theme: Theme = .dark
    private var overlaySpec: OverlaySpec = []
    
    private let ema20Calculator = EMACalculator(period: 20)
    private let ema50Calculator = EMACalculator(period: 50)
    private let sma20Calculator = SMACalculator(period: 20)
    private let sma50Calculator = SMACalculator(period: 50)
    private let bollingerCalculator = BollingerBandsCalculator(period: 20)
    
    override init() {
        super.init()
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        let layers = [ema20Layer, ema50Layer, sma20Layer, sma50Layer, bollingerUpperLayer, bollingerMiddleLayer, bollingerLowerLayer]
        
        for layer in layers {
            addSublayer(layer)
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 1.5
            layer.isHidden = true
        }
        
        ema20Layer.strokeColor = theme.overlayColors[0].cgColor
        ema50Layer.strokeColor = theme.overlayColors[1].cgColor
        sma20Layer.strokeColor = theme.overlayColors[2].cgColor
        sma50Layer.strokeColor = theme.overlayColors[3].cgColor
        bollingerUpperLayer.strokeColor = theme.overlayColors[4].cgColor
        bollingerMiddleLayer.strokeColor = theme.overlayColors[4].cgColor
        bollingerLowerLayer.strokeColor = theme.overlayColors[4].cgColor
        
        bollingerUpperLayer.lineDashPattern = [4, 4]
        bollingerLowerLayer.lineDashPattern = [4, 4]
    }
    
    func configure(candles: [Candle], theme: Theme, overlaySpec: OverlaySpec) {
        self.candles = candles
        self.theme = theme
        self.overlaySpec = overlaySpec
        
        updateOverlays()
    }
    
    private func updateOverlays() {
        guard !candles.isEmpty else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let prices = candles.map(\.close)
        let priceRange = getPriceRange()
        
        if overlaySpec.contains(.ema20) {
            let ema20Values = ema20Calculator.calculate(prices: prices)
            updateLayer(ema20Layer, with: ema20Values, priceRange: priceRange)
            ema20Layer.isHidden = false
        } else {
            ema20Layer.isHidden = true
        }
        
        if overlaySpec.contains(.ema50) {
            let ema50Values = ema50Calculator.calculate(prices: prices)
            updateLayer(ema50Layer, with: ema50Values, priceRange: priceRange)
            ema50Layer.isHidden = false
        } else {
            ema50Layer.isHidden = true
        }
        
        if overlaySpec.contains(.sma20) {
            let sma20Values = sma20Calculator.calculate(prices: prices)
            updateLayer(sma20Layer, with: sma20Values, priceRange: priceRange)
            sma20Layer.isHidden = false
        } else {
            sma20Layer.isHidden = true
        }
        
        if overlaySpec.contains(.sma50) {
            let sma50Values = sma50Calculator.calculate(prices: prices)
            updateLayer(sma50Layer, with: sma50Values, priceRange: priceRange)
            sma50Layer.isHidden = false
        } else {
            sma50Layer.isHidden = true
        }
        
        if overlaySpec.contains(.bollinger20) {
            let bollingerValues = bollingerCalculator.calculate(prices: prices)
            updateBollingerLayers(with: bollingerValues, priceRange: priceRange)
            bollingerUpperLayer.isHidden = false
            bollingerMiddleLayer.isHidden = false
            bollingerLowerLayer.isHidden = false
        } else {
            bollingerUpperLayer.isHidden = true
            bollingerMiddleLayer.isHidden = true
            bollingerLowerLayer.isHidden = true
        }
        
        CATransaction.commit()
    }
    
    private func updateLayer(_ layer: CAShapeLayer, with values: [CGFloat?], priceRange: (min: CGFloat, max: CGFloat, range: CGFloat)) {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let path = CGMutablePath()
        let spacing = bounds.width / CGFloat(values.count - 1)
        var hasStartPoint = false
        
        for (index, value) in values.enumerated() {
            guard let value = value else { continue }
            
            let x = CGFloat(index) * spacing
            let y = bounds.height - ((value - priceRange.min) / priceRange.range) * bounds.height
            
            if !hasStartPoint {
                path.move(to: CGPoint(x: x, y: y))
                hasStartPoint = true
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        layer.path = path
    }
    
    private func updateBollingerLayers(with values: [BollingerBandsCalculator.BollingerBands], priceRange: (min: CGFloat, max: CGFloat, range: CGFloat)) {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let spacing = bounds.width / CGFloat(values.count - 1)
        
        let upperPath = CGMutablePath()
        let middlePath = CGMutablePath()
        let lowerPath = CGMutablePath()
        
        var hasStartPoint = false
        
        for (index, bands) in values.enumerated() {
            guard let upper = bands.upper, let middle = bands.middle, let lower = bands.lower else { continue }
            
            let x = CGFloat(index) * spacing
            let upperY = bounds.height - ((upper - priceRange.min) / priceRange.range) * bounds.height
            let middleY = bounds.height - ((middle - priceRange.min) / priceRange.range) * bounds.height
            let lowerY = bounds.height - ((lower - priceRange.min) / priceRange.range) * bounds.height
            
            if !hasStartPoint {
                upperPath.move(to: CGPoint(x: x, y: upperY))
                middlePath.move(to: CGPoint(x: x, y: middleY))
                lowerPath.move(to: CGPoint(x: x, y: lowerY))
                hasStartPoint = true
            } else {
                upperPath.addLine(to: CGPoint(x: x, y: upperY))
                middlePath.addLine(to: CGPoint(x: x, y: middleY))
                lowerPath.addLine(to: CGPoint(x: x, y: lowerY))
            }
        }
        
        bollingerUpperLayer.path = upperPath
        bollingerMiddleLayer.path = middlePath
        bollingerLowerLayer.path = lowerPath
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
}