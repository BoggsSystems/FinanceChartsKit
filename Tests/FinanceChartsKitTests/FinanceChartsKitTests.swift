import XCTest
@testable import FinanceChartsKit

final class FinanceChartsKitTests: XCTestCase {
    
    func testCandleProperties() {
        let candle = Candle(
            timestamp: 1699200000,
            open: 100,
            high: 110,
            low: 90,
            close: 105,
            volume: 50000
        )
        
        XCTAssertTrue(candle.isGreen, "Candle should be green when close > open")
        XCTAssertEqual(candle.bodyHigh, 105, "Body high should be close when green")
        XCTAssertEqual(candle.bodyLow, 100, "Body low should be open when green")
        XCTAssertEqual(candle.range, 20, "Range should be high - low")
        XCTAssertEqual(candle.bodyHeight, 5, "Body height should be abs(close - open)")
    }
    
    func testTimeframeProperties() {
        XCTAssertEqual(Timeframe.m1.seconds, 60)
        XCTAssertEqual(Timeframe.m5.seconds, 300)
        XCTAssertEqual(Timeframe.h1.seconds, 3600)
        XCTAssertEqual(Timeframe.d1.seconds, 86400)
        
        XCTAssertEqual(Timeframe.m1.next, .m5)
        XCTAssertEqual(Timeframe.m5.previous, .m1)
        XCTAssertEqual(Timeframe.d1.next, .d1)
        XCTAssertEqual(Timeframe.m1.previous, .m1)
    }
    
    func testOverlaySpec() {
        var spec = OverlaySpec.ema20
        spec.insert(.ema50)
        
        XCTAssertTrue(spec.contains(.ema20))
        XCTAssertTrue(spec.contains(.ema50))
        XCTAssertFalse(spec.contains(.sma20))
        
        let names = spec.displayNames
        XCTAssertTrue(names.contains("EMA 20"))
        XCTAssertTrue(names.contains("EMA 50"))
    }
    
    func testIndicatorSpec() {
        var spec = IndicatorSpec.rsi14
        spec.insert(.macd)
        
        XCTAssertTrue(spec.contains(.rsi14))
        XCTAssertTrue(spec.contains(.macd))
        XCTAssertFalse(spec.contains(.stochastic))
        
        let names = spec.displayNames
        XCTAssertTrue(names.contains("RSI 14"))
        XCTAssertTrue(names.contains("MACD"))
    }
    
    func testOHLCBuilder() {
        let builder = OHLCBuilder(timeframe: .h1)
        
        let tick1 = Tick(timestamp: 3600, price: 100, volume: 1000)
        let result1 = builder.ingest(tick1)
        
        XCTAssertNotNil(result1.updated)
        XCTAssertNil(result1.appended)
        
        let tick2 = Tick(timestamp: 3650, price: 105, volume: 500)
        let result2 = builder.ingest(tick2)
        
        XCTAssertNotNil(result2.updated)
        XCTAssertNil(result2.appended)
        
        let tick3 = Tick(timestamp: 7200, price: 102, volume: 800)
        let result3 = builder.ingest(tick3)
        
        XCTAssertNotNil(result3.updated)
        XCTAssertNotNil(result3.appended)
    }
    
    func testChartControllerBasicOperations() {
        let controller = ChartController()
        
        controller.symbol = "TEST"
        XCTAssertEqual(controller.symbol, "TEST")
        
        controller.timeframe = .m5
        XCTAssertEqual(controller.timeframe, .m5)
        
        let testCandles = [
            Candle(timestamp: 0, open: 100, high: 110, low: 90, close: 105, volume: 1000),
            Candle(timestamp: 300, open: 105, high: 115, low: 95, close: 110, volume: 1500)
        ]
        
        controller.setData(testCandles)
        
        let snapshot = controller.snapshot()
    }
}
