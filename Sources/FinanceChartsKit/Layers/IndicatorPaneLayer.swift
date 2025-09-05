import Foundation
import QuartzCore
import UIKit

final class IndicatorPaneLayer: CALayer {
    private let rsiLayer = CAShapeLayer()
    private let rsiUpperBandLayer = CAShapeLayer()
    private let rsiLowerBandLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    
    private var candles: [Candle] = []
    private var theme: Theme = .dark
    private var indicatorSpec: IndicatorSpec = []
    
    private let rsiCalculator = RSICalculator(period: 14)
    
    override init() {
        super.init()
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        addSublayer(backgroundLayer)
        addSublayer(rsiUpperBandLayer)
        addSublayer(rsiLowerBandLayer)
        addSublayer(rsiLayer)
        
        backgroundLayer.fillColor = theme.backgroundColor.withAlphaComponent(0.3).cgColor
        
        rsiLayer.fillColor = UIColor.clear.cgColor
        rsiLayer.strokeColor = theme.indicatorColors[0].cgColor
        rsiLayer.lineWidth = 2.0
        
        rsiUpperBandLayer.fillColor = UIColor.clear.cgColor
        rsiUpperBandLayer.strokeColor = theme.gridColor.cgColor
        rsiUpperBandLayer.lineWidth = 1.0
        rsiUpperBandLayer.lineDashPattern = [2, 2]
        
        rsiLowerBandLayer.fillColor = UIColor.clear.cgColor
        rsiLowerBandLayer.strokeColor = theme.gridColor.cgColor
        rsiLowerBandLayer.lineWidth = 1.0
        rsiLowerBandLayer.lineDashPattern = [2, 2]
        
        isHidden = true
    }
    
    func configure(candles: [Candle], theme: Theme, indicatorSpec: IndicatorSpec) {
        self.candles = candles
        self.theme = theme
        self.indicatorSpec = indicatorSpec
        
        updateLayers()
    }
    
    private func updateLayers() {
        guard !candles.isEmpty else {
            isHidden = true
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if indicatorSpec.contains(.rsi14) {
            updateRSILayer()
            isHidden = false
        } else {
            isHidden = true
        }
        
        CATransaction.commit()
    }
    
    private func updateRSILayer() {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        backgroundLayer.path = CGPath(rect: bounds, transform: nil)
        
        let prices = candles.map(\.close)
        let rsiValues = rsiCalculator.calculate(prices: prices)
        
        updateRSIBands()
        
        let path = CGMutablePath()
        let spacing = bounds.width / CGFloat(rsiValues.count - 1)
        var hasStartPoint = false
        
        for (index, rsiValue) in rsiValues.enumerated() {
            guard let rsi = rsiValue else { continue }
            
            let x = CGFloat(index) * spacing
            let y = bounds.height - (rsi / 100.0) * bounds.height
            
            if !hasStartPoint {
                path.move(to: CGPoint(x: x, y: y))
                hasStartPoint = true
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        rsiLayer.path = path
    }
    
    private func updateRSIBands() {
        let bounds = self.bounds
        
        let upperBandPath = CGMutablePath()
        let upperY = bounds.height - (70.0 / 100.0) * bounds.height
        upperBandPath.move(to: CGPoint(x: 0, y: upperY))
        upperBandPath.addLine(to: CGPoint(x: bounds.width, y: upperY))
        rsiUpperBandLayer.path = upperBandPath
        
        let lowerBandPath = CGMutablePath()
        let lowerY = bounds.height - (30.0 / 100.0) * bounds.height
        lowerBandPath.move(to: CGPoint(x: 0, y: lowerY))
        lowerBandPath.addLine(to: CGPoint(x: bounds.width, y: lowerY))
        rsiLowerBandLayer.path = lowerBandPath
    }
}