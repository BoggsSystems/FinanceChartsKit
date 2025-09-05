import XCTest
@testable import FinanceChartsKit

final class DownsamplerTests: XCTestCase {
    
    func testLTTBDownsampling() {
        let candles = generateTestCandles(count: 1000)
        let targetPoints = 100
        
        let downsampled = Downsampler.lttb(data: candles, targetPoints: targetPoints)
        
        XCTAssertEqual(downsampled.count, targetPoints, "Should return exactly target points")
        XCTAssertEqual(downsampled.first, candles.first, "Should preserve first candle")
        XCTAssertEqual(downsampled.last, candles.last, "Should preserve last candle")
        
        for i in 1..<downsampled.count {
            XCTAssertTrue(downsampled[i].timestamp >= downsampled[i-1].timestamp, "Timestamps should be in order")
        }
    }
    
    func testLTTBPreservesExtremes() {
        var candles = generateTestCandles(count: 100)
        
        candles[50] = Candle(timestamp: candles[50].timestamp, open: 100, high: 1000, low: 1, close: 100, volume: 1000)
        
        let downsampled = Downsampler.lttb(data: candles, targetPoints: 20)
        
        let hasExtreme = downsampled.contains { candle in
            candle.high == 1000 || candle.low == 1
        }
        
        XCTAssertTrue(hasExtreme, "Should preserve extreme values")
    }
    
    func testMinMaxDownsampling() {
        let candles = generateTestCandles(count: 1000)
        let targetWidth = 100
        
        let downsampled = Downsampler.minMaxDownsample(data: candles, targetPixelWidth: targetWidth)
        
        XCTAssertTrue(downsampled.count <= candles.count, "Should not increase data points")
        XCTAssertTrue(downsampled.count >= targetWidth, "Should provide sufficient points for visualization")
        
        for i in 1..<downsampled.count {
            XCTAssertTrue(downsampled[i].timestamp >= downsampled[i-1].timestamp, "Timestamps should be in order")
        }
    }
    
    func testDownsamplingWithSmallDataset() {
        let candles = generateTestCandles(count: 10)
        let targetPoints = 50
        
        let downsampled = Downsampler.lttb(data: candles, targetPoints: targetPoints)
        
        XCTAssertEqual(downsampled.count, candles.count, "Should return original data when target is larger than data")
    }
    
    func testDownsamplingWithZeroTarget() {
        let candles = generateTestCandles(count: 100)
        
        let downsampled = Downsampler.lttb(data: candles, targetPoints: 0)
        
        XCTAssertEqual(downsampled.count, candles.count, "Should return original data when target is zero")
    }
    
    func testPerformanceLTTB() {
        let candles = generateTestCandles(count: 10000)
        
        measure {
            _ = Downsampler.lttb(data: candles, targetPoints: 1000)
        }
    }
    
    func testPerformanceMinMax() {
        let candles = generateTestCandles(count: 10000)
        
        measure {
            _ = Downsampler.minMaxDownsample(data: candles, targetPixelWidth: 1920)
        }
    }
    
    private func generateTestCandles(count: Int) -> [Candle] {
        let baseTime: TimeInterval = 1699200000
        let basePrice: CGFloat = 100
        
        return (0..<count).map { i in
            let price = basePrice + CGFloat(sin(Double(i) * 0.1)) * 10 + CGFloat.random(in: -2...2)
            return Candle(
                timestamp: baseTime + TimeInterval(i * 3600),
                open: price,
                high: price + CGFloat.random(in: 0...3),
                low: price - CGFloat.random(in: 0...3),
                close: price + CGFloat.random(in: -1...1),
                volume: CGFloat.random(in: 1000...10000)
            )
        }
    }
}