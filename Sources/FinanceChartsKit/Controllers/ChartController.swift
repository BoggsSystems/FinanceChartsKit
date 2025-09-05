import Foundation
import UIKit

public final class ChartController: ObservableObject {
    @Published public var symbol: String = ""
    @Published public var timeframe: Timeframe = .h1
    @Published public var overlays: OverlaySpec = []
    @Published public var indicators: IndicatorSpec = []
    
    private var candles: [Candle] = []
    private var theme: Theme = .dark
    private var zoomScale: CGFloat = 1.0
    private var panOffset: Int = 0
    private var crosshairX: CGFloat?
    private var isConnected: Bool = true
    
    private weak var chartView: ChartView?
    private let renderScheduler = RenderScheduler(targetFPS: 60)
    private var needsUpdate = false
    
    public init() {}
    
    public func setData(_ candles: [Candle]) {
        self.candles = candles
        panOffset = 0
        scheduleUpdate()
    }
    
    public func updateLast(_ candle: Candle) {
        guard !candles.isEmpty else { return }
        candles[candles.count - 1] = candle
        scheduleUpdate()
    }
    
    public func append(_ candle: Candle) {
        candles.append(candle)
        scheduleUpdate()
    }
    
    public func setZoom(_ scale: CGFloat) {
        zoomScale = max(0.1, min(10.0, scale))
        scheduleUpdate()
    }
    
    public func pan(byBars: Int) {
        let maxOffset = max(0, candles.count - getVisibleCandleCount())
        panOffset = max(0, min(maxOffset, panOffset + byBars))
        scheduleUpdate()
    }
    
    public func setCrosshair(x: CGFloat?) {
        crosshairX = x
        chartView?.updateCrosshair(x: x)
    }
    
    public func snapshot() -> UIImage? {
        return chartView?.snapshot()
    }
    
    public func setTheme(_ theme: Theme) {
        self.theme = theme
        scheduleUpdate()
    }
    
    public func setConnectionStatus(_ connected: Bool) {
        self.isConnected = connected
        scheduleUpdate()
    }
    
    internal func attachChartView(_ chartView: ChartView) {
        self.chartView = chartView
        startRenderLoop()
        scheduleUpdate()
    }
    
    internal func detachChartView() {
        stopRenderLoop()
        self.chartView = nil
    }
    
    private func startRenderLoop() {
        renderScheduler.start { [weak self] in
            self?.performUpdate()
        }
    }
    
    private func stopRenderLoop() {
        renderScheduler.stop()
    }
    
    private func scheduleUpdate() {
        needsUpdate = true
    }
    
    private func performUpdate() {
        guard needsUpdate, let chartView = chartView else { return }
        needsUpdate = false
        
        let visibleCandles = getVisibleCandles()
        let currentPrice = visibleCandles.last?.close ?? 0
        let firstPrice = visibleCandles.first?.close ?? currentPrice
        let percentChange = firstPrice != 0 ? ((currentPrice - firstPrice) / firstPrice) * 100 : 0
        
        chartView.configure(
            candles: visibleCandles,
            symbol: symbol,
            price: currentPrice,
            percentChange: percentChange,
            timeframe: timeframe,
            overlays: overlays,
            indicators: indicators,
            theme: theme,
            isConnected: isConnected
        )
    }
    
    private func getVisibleCandles() -> [Candle] {
        let visibleCount = getVisibleCandleCount()
        let startIndex = max(0, min(candles.count - visibleCount, panOffset))
        let endIndex = min(candles.count, startIndex + visibleCount)
        
        return Array(candles[startIndex..<endIndex])
    }
    
    private func getVisibleCandleCount() -> Int {
        let baseCount = 100
        return Int(CGFloat(baseCount) / zoomScale)
    }
}

extension ChartController {
    public func cycleTimeframeUp() {
        timeframe = timeframe.next
        scheduleUpdate()
    }
    
    public func cycleTimeframeDown() {
        timeframe = timeframe.previous
        scheduleUpdate()
    }
    
    public func toggleOverlay(_ overlay: OverlaySpec) {
        if overlays.contains(overlay) {
            overlays.remove(overlay)
        } else {
            overlays.insert(overlay)
        }
        scheduleUpdate()
    }
    
    public func toggleIndicator(_ indicator: IndicatorSpec) {
        if indicators.contains(indicator) {
            indicators.remove(indicator)
        } else {
            indicators.insert(indicator)
        }
        scheduleUpdate()
    }
    
    public func resetZoomAndPan() {
        zoomScale = 1.0
        panOffset = 0
        scheduleUpdate()
    }
}