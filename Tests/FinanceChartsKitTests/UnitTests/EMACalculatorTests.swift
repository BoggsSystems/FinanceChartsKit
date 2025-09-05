import XCTest
@testable import FinanceChartsKit

final class EMACalculatorTests: XCTestCase {
    var emaCalculator: EMACalculator!
    var smaCalculator: SMACalculator!
    var bollingerCalculator: BollingerBandsCalculator!
    
    override func setUp() {
        super.setUp()
        emaCalculator = EMACalculator(period: 10)
        smaCalculator = SMACalculator(period: 10)
        bollingerCalculator = BollingerBandsCalculator(period: 20, standardDeviations: 2.0)
    }
    
    override func tearDown() {
        emaCalculator = nil
        smaCalculator = nil
        bollingerCalculator = nil
        super.tearDown()
    }
    
    func testEMACalculation() {
        let prices: [CGFloat] = [22.27, 22.19, 22.08, 22.17, 22.18, 22.13, 22.23, 22.43, 22.24, 22.29, 22.15, 22.39, 22.38, 22.61, 23.36]
        
        let emaValues = emaCalculator.calculate(prices: prices)
        
        XCTAssertEqual(emaValues.count, prices.count)
        
        for i in 0..<9 {
            XCTAssertNil(emaValues[i], "EMA should be nil for the first 9 values")
        }
        
        guard let firstEMA = emaValues[9] else {
            XCTFail("First EMA value should not be nil")
            return
        }
        
        let expectedSMA = prices.prefix(10).reduce(0, +) / 10
        XCTAssertEqual(firstEMA, expectedSMA, accuracy: 0.01, "First EMA should equal SMA")
        
        guard let secondEMA = emaValues[10] else {
            XCTFail("Second EMA value should not be nil")
            return
        }
        
        XCTAssertNotEqual(secondEMA, firstEMA, "EMA values should change")
    }
    
    func testSMACalculation() {
        let prices: [CGFloat] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        
        let smaValues = smaCalculator.calculate(prices: prices)
        
        XCTAssertEqual(smaValues.count, prices.count)
        
        for i in 0..<9 {
            XCTAssertNil(smaValues[i], "SMA should be nil for the first 9 values")
        }
        
        guard let firstSMA = smaValues[9] else {
            XCTFail("First SMA value should not be nil")
            return
        }
        
        XCTAssertEqual(firstSMA, 5.5, accuracy: 0.01, "First SMA should be 5.5")
        
        guard let secondSMA = smaValues[10] else {
            XCTFail("Second SMA value should not be nil")
            return
        }
        
        XCTAssertEqual(secondSMA, 6.5, accuracy: 0.01, "Second SMA should be 6.5")
    }
    
    func testBollingerBands() {
        let prices = Array(0..<50).map { CGFloat($0) + 100 + CGFloat.random(in: -5...5) }
        
        let bands = bollingerCalculator.calculate(prices: prices)
        
        XCTAssertEqual(bands.count, prices.count)
        
        for i in 0..<19 {
            XCTAssertNil(bands[i].upper, "Bollinger upper band should be nil for the first 19 values")
            XCTAssertNil(bands[i].middle, "Bollinger middle band should be nil for the first 19 values")
            XCTAssertNil(bands[i].lower, "Bollinger lower band should be nil for the first 19 values")
        }
        
        guard let firstBand = bands[19],
              let upper = firstBand.upper,
              let middle = firstBand.middle,
              let lower = firstBand.lower else {
            XCTFail("First Bollinger band values should not be nil")
            return
        }
        
        XCTAssertTrue(upper > middle, "Upper band should be above middle")
        XCTAssertTrue(middle > lower, "Middle should be above lower band")
        XCTAssertTrue(upper - middle > 0, "Band width should be positive")
        XCTAssertTrue(middle - lower > 0, "Band width should be positive")
    }
    
    func testPerformanceEMACalculation() {
        let prices = (0..<5000).map { _ in CGFloat.random(in: 100...200) }
        
        measure {
            _ = emaCalculator.calculate(prices: prices)
        }
    }
}