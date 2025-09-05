import XCTest
@testable import FinanceChartsKit

final class RenderPerformanceTests: XCTestCase {
    
    func testChartControllerPerformanceWith500Candles() {
        let candles = generatePerformanceCandles(count: 500)
        let controller = ChartController()
        
        measure {
            controller.setData(candles)
        }
    }
    
    func testChartControllerPerformanceWith1500Candles() {
        let candles = generatePerformanceCandles(count: 1500)
        let controller = ChartController()
        
        measure {
            controller.setData(candles)
        }
    }
    
    func testChartControllerPerformanceWith3000Candles() {
        let candles = generatePerformanceCandles(count: 3000)
        let controller = ChartController()
        
        measure {
            controller.setData(candles)
        }
    }
    
    func testLiveUpdatePerformance() {
        let candles = generatePerformanceCandles(count: 1000)
        let controller = ChartController()
        controller.setData(candles)
        
        let updateCandle = Candle(
            timestamp: Date().timeIntervalSince1970,
            open: 100,
            high: 105,
            low: 95,
            close: 102,
            volume: 50000
        )
        
        measure {
            for _ in 0..<100 {
                controller.updateLast(updateCandle)
            }
        }
    }
    
    func testMemoryStabilityDuringUpdates() {
        let controller = ChartController()
        let initialCandles = generatePerformanceCandles(count: 1000)
        controller.setData(initialCandles)
        
        measure {
            for i in 0..<1000 {
                let newCandle = Candle(
                    timestamp: Date().timeIntervalSince1970 + TimeInterval(i),
                    open: 100 + CGFloat(i % 10),
                    high: 105 + CGFloat(i % 10),
                    low: 95 + CGFloat(i % 10),
                    close: 102 + CGFloat(i % 10),
                    volume: 50000
                )
                controller.updateLast(newCandle)
            }
        }
    }
    
    func testCalculatorPerformanceAtScale() {
        let prices = (0..<5000).map { _ in CGFloat.random(in: 50...500) }
        
        measure {
            let rsiCalculator = RSICalculator()
            let emaCalculator = EMACalculator(period: 20)
            let smaCalculator = SMACalculator(period: 20)
            let bbCalculator = BollingerBandsCalculator()
            
            _ = rsiCalculator.calculate(prices: prices)
            _ = emaCalculator.calculate(prices: prices)
            _ = smaCalculator.calculate(prices: prices)
            _ = bbCalculator.calculate(prices: prices)
        }
    }
    
    func testDownsamplingPerformanceAtScale() {
        let candles = generatePerformanceCandles(count: 10000)
        
        measure {
            _ = Downsampler.lttb(data: candles, targetPoints: 1000)
            _ = Downsampler.minMaxDownsample(data: candles, targetPixelWidth: 1920)
        }
    }
    
    private func generatePerformanceCandles(count: Int) -> [Candle] {
        let baseTime: TimeInterval = Date().timeIntervalSince1970 - TimeInterval(count * 3600)
        let basePrice: CGFloat = 250.0
        var currentPrice = basePrice
        
        return (0..<count).map { i in
            let change = CGFloat.random(in: -0.02...0.02) * currentPrice
            let open = currentPrice
            let close = currentPrice + change
            let high = max(open, close) + CGFloat.random(in: 0...0.005) * currentPrice
            let low = min(open, close) - CGFloat.random(in: 0...0.005) * currentPrice
            let volume = CGFloat.random(in: 10000...100000)
            
            currentPrice = close
            
            return Candle(
                timestamp: baseTime + TimeInterval(i * 3600),
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
    }
}