import Foundation
import UIKit
import QuartzCore

final class ChartView: UIView {
    private let priceLayer = PriceLayer()
    private let overlayLayer = OverlayLayer()
    private let indicatorPaneLayer = IndicatorPaneLayer()
    private let crosshairLayer = CrosshairLayer()
    private let hudLayer = HUDLayer()
    
    private var currentCandles: [Candle] = []
    private var currentTheme: Theme = .dark
    private var timeScale: TimeScale
    
    private weak var controller: ChartController?
    
    override init(frame: CGRect) {
        timeScale = TimeScale(timeframe: .h1)
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        timeScale = TimeScale(timeframe: .h1)
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        backgroundColor = UIColor.clear
        
        layer.addSublayer(priceLayer)
        layer.addSublayer(overlayLayer)
        layer.addSublayer(indicatorPaneLayer)
        layer.addSublayer(crosshairLayer)
        layer.addSublayer(hudLayer)
    }
    
    func attachController(_ controller: ChartController) {
        self.controller = controller
        controller.attachChartView(self)
    }
    
    func detachController() {
        controller?.detachChartView()
        controller = nil
    }
    
    func configure(
        candles: [Candle],
        symbol: String,
        price: CGFloat,
        percentChange: CGFloat,
        timeframe: Timeframe,
        overlays: OverlaySpec,
        indicators: IndicatorSpec,
        theme: Theme,
        isConnected: Bool
    ) {
        currentCandles = candles
        currentTheme = theme
        timeScale = TimeScale(timeframe: timeframe)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateLayers(
                candles: candles,
                symbol: symbol,
                price: price,
                percentChange: percentChange,
                timeframe: timeframe,
                overlays: overlays,
                indicators: indicators,
                theme: theme,
                isConnected: isConnected
            )
        }
    }
    
    private func updateLayers(
        candles: [Candle],
        symbol: String,
        price: CGFloat,
        percentChange: CGFloat,
        timeframe: Timeframe,
        overlays: OverlaySpec,
        indicators: IndicatorSpec,
        theme: Theme,
        isConnected: Bool
    ) {
        guard !candles.isEmpty else { return }
        
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let candleWidth = timeScale.getOptimalCandleWidth(
            containerWidth: bounds.width,
            visibleCandles: candles.count
        )
        let showCandlesticks = timeScale.shouldShowCandlesticks(candleWidth: candleWidth)
        
        let hasIndicators = !indicators.isEmpty
        let priceHeight = hasIndicators ? bounds.height * 0.7 : bounds.height - 60
        let indicatorHeight = hasIndicators ? bounds.height * 0.3 : 0
        let hudHeight: CGFloat = 60
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        priceLayer.frame = CGRect(x: 0, y: hudHeight, width: bounds.width, height: priceHeight)
        priceLayer.configure(
            candles: candles,
            theme: theme,
            showVolume: true,
            showCandlesticks: showCandlesticks
        )
        
        overlayLayer.frame = CGRect(x: 0, y: hudHeight, width: bounds.width, height: priceHeight)
        overlayLayer.configure(candles: candles, theme: theme, overlaySpec: overlays)
        
        if hasIndicators {
            indicatorPaneLayer.frame = CGRect(
                x: 0,
                y: hudHeight + priceHeight,
                width: bounds.width,
                height: indicatorHeight
            )
            indicatorPaneLayer.configure(candles: candles, theme: theme, indicatorSpec: indicators)
        }
        
        crosshairLayer.frame = CGRect(x: 0, y: hudHeight, width: bounds.width, height: priceHeight)
        let rsiValues: [CGFloat?] = indicators.contains(.rsi14) ? RSICalculator().calculate(prices: candles.map(\.close)) : []
        crosshairLayer.configure(candles: candles, theme: theme, showRSI: indicators.contains(.rsi14), rsiValues: rsiValues)
        
        hudLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: hudHeight)
        hudLayer.configure(
            symbol: symbol,
            price: price,
            percentChange: percentChange,
            timeframe: timeframe,
            theme: theme,
            isConnected: isConnected
        )
        
        CATransaction.commit()
    }
    
    func updateCrosshair(x: CGFloat?) {
        crosshairLayer.setCrosshair(x: x)
    }
    
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !currentCandles.isEmpty {
            let timeframe = controller?.timeframe ?? .h1
            updateLayers(
                candles: currentCandles,
                symbol: controller?.symbol ?? "",
                price: currentCandles.last?.close ?? 0,
                percentChange: 0,
                timeframe: timeframe,
                overlays: controller?.overlays ?? [],
                indicators: controller?.indicators ?? [],
                theme: currentTheme,
                isConnected: true
            )
        }
    }
}