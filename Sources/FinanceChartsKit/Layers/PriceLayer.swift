import Foundation
import QuartzCore
import UIKit

final class PriceLayer: CALayer {
    private let candlestickLayer = CAShapeLayer()
    private let wickLayer = CAShapeLayer()
    private let volumeLayer = CAShapeLayer()
    private let lineLayer = CAShapeLayer()
    
    private var candles: [Candle] = []
    private var theme: Theme = .dark
    private var showVolume = false
    private var showCandlesticks = true
    
    override init() {
        super.init()
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        addSublayer(volumeLayer)
        addSublayer(wickLayer)
        addSublayer(candlestickLayer)
        addSublayer(lineLayer)
        
        candlestickLayer.fillColor = UIColor.clear.cgColor
        wickLayer.fillColor = UIColor.clear.cgColor
        volumeLayer.fillColor = theme.volumeColor.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = theme.upColor.cgColor
        lineLayer.lineWidth = 1.5
    }
    
    func configure(candles: [Candle], theme: Theme, showVolume: Bool, showCandlesticks: Bool) {
        self.candles = candles
        self.theme = theme
        self.showVolume = showVolume
        self.showCandlesticks = showCandlesticks
        
        updateLayers()
    }
    
    private func updateLayers() {
        guard !candles.isEmpty else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if showCandlesticks {
            updateCandlestickLayers()
            lineLayer.isHidden = true
        } else {
            updateLineLayer()
            candlestickLayer.isHidden = true
            wickLayer.isHidden = true
        }
        
        if showVolume {
            updateVolumeLayer()
            volumeLayer.isHidden = false
        } else {
            volumeLayer.isHidden = true
        }
        
        CATransaction.commit()
    }
    
    private func updateCandlestickLayers() {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let priceRange = getPriceRange()
        let candleWidth = max(1.0, bounds.width / CGFloat(candles.count) - 1.0)
        let candleSpacing = bounds.width / CGFloat(candles.count)
        
        let candlePath = CGMutablePath()
        let wickPath = CGMutablePath()
        
        for (index, candle) in candles.enumerated() {
            let x = CGFloat(index) * candleSpacing + candleSpacing / 2
            let openY = bounds.height - ((candle.open - priceRange.min) / priceRange.range) * bounds.height
            let closeY = bounds.height - ((candle.close - priceRange.min) / priceRange.range) * bounds.height
            let highY = bounds.height - ((candle.high - priceRange.min) / priceRange.range) * bounds.height
            let lowY = bounds.height - ((candle.low - priceRange.min) / priceRange.range) * bounds.height
            
            let bodyTop = min(openY, closeY)
            let bodyBottom = max(openY, closeY)
            let bodyHeight = bodyBottom - bodyTop
            
            wickPath.move(to: CGPoint(x: x, y: highY))
            wickPath.addLine(to: CGPoint(x: x, y: lowY))
            
            let bodyRect = CGRect(x: x - candleWidth / 2, y: bodyTop, width: candleWidth, height: max(1.0, bodyHeight))
            candlePath.addRect(bodyRect)
        }
        
        candlestickLayer.path = candlePath
        candlestickLayer.fillColor = theme.upColor.cgColor
        candlestickLayer.isHidden = false
        
        wickLayer.path = wickPath
        wickLayer.strokeColor = theme.textColor.cgColor
        wickLayer.lineWidth = 1.0
        wickLayer.isHidden = false
    }
    
    private func updateLineLayer() {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 && !candles.isEmpty else { return }
        
        let priceRange = getPriceRange()
        let spacing = bounds.width / CGFloat(candles.count - 1)
        
        let linePath = CGMutablePath()
        
        for (index, candle) in candles.enumerated() {
            let x = CGFloat(index) * spacing
            let y = bounds.height - ((candle.close - priceRange.min) / priceRange.range) * bounds.height
            
            if index == 0 {
                linePath.move(to: CGPoint(x: x, y: y))
            } else {
                linePath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        lineLayer.path = linePath
        lineLayer.isHidden = false
    }
    
    private func updateVolumeLayer() {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let maxVolume = candles.map(\.volume).max() ?? 1
        let volumeHeight = bounds.height * 0.2
        let candleSpacing = bounds.width / CGFloat(candles.count)
        
        let volumePath = CGMutablePath()
        
        for (index, candle) in candles.enumerated() {
            let x = CGFloat(index) * candleSpacing
            let height = (candle.volume / maxVolume) * volumeHeight
            let rect = CGRect(x: x, y: bounds.height - height, width: max(1.0, candleSpacing - 1), height: height)
            volumePath.addRect(rect)
        }
        
        volumeLayer.path = volumePath
        volumeLayer.fillColor = theme.volumeColor.cgColor
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