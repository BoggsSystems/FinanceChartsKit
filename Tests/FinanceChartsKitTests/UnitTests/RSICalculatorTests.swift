import XCTest
@testable import FinanceChartsKit

final class RSICalculatorTests: XCTestCase {
    var calculator: RSICalculator!
    
    override func setUp() {
        super.setUp()
        calculator = RSICalculator(period: 14)
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    func testRSICalculationWithKnownValues() {
        let prices: [CGFloat] = [
            44.0, 44.25, 44.50, 43.75, 44.50, 44.75, 44.50, 44.25,
            44.00, 44.25, 45.50, 47.75, 47.00, 46.75, 46.50, 46.25,
            47.75, 47.50, 47.25, 48.00, 47.75, 47.50, 47.25, 47.75,
            50.25, 51.25, 51.50, 51.75, 51.50, 50.00
        ]
        
        let rsiValues = calculator.calculate(prices: prices)
        
        XCTAssertEqual(rsiValues.count, prices.count)
        
        for i in 0..<14 {
            XCTAssertNil(rsiValues[i], "RSI should be nil for the first \(14) values")
        }
        
        guard let firstRSI = rsiValues[14] else {
            XCTFail("First RSI value should not be nil")
            return
        }
        
        XCTAssertTrue(firstRSI > 50, "First RSI should be above 50 for upward trend")
        XCTAssertTrue(firstRSI < 80, "First RSI should be below 80")
        
        guard let lastRSI = rsiValues.last, let lastRSIValue = lastRSI else {
            XCTFail("Last RSI value should not be nil")
            return
        }
        
        XCTAssertTrue(lastRSIValue > 70, "Last RSI should indicate overbought condition")
    }
    
    func testRSIBoundaries() {
        calculator.reset()
        
        let constantUpPrices = Array(1...30).map { CGFloat($0) }
        let rsiValues = calculator.calculate(prices: constantUpPrices)
        
        for (index, rsi) in rsiValues.enumerated() {
            guard let rsiValue = rsi else { continue }
            XCTAssertTrue(rsiValue >= 0 && rsiValue <= 100, "RSI at index \(index) should be between 0 and 100, got \(rsiValue)")
        }
        
        if let lastRSI = rsiValues.last, let lastRSIValue = lastRSI {
            XCTAssertTrue(lastRSIValue > 90, "RSI for constantly rising prices should approach 100")
        }
    }
    
    func testRSIReset() {
        let prices: [CGFloat] = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
        _ = calculator.calculate(prices: prices)
        
        calculator.reset()
        
        let newPrices: [CGFloat] = [50, 51, 52]
        let newRSI = calculator.calculate(prices: newPrices)
        
        for rsi in newRSI {
            XCTAssertNil(rsi, "RSI should be nil after reset with insufficient data")
        }
    }
    
    func testPerformanceRSICalculation() {
        let prices = (0..<5000).map { _ in CGFloat.random(in: 100...200) }
        
        measure {
            _ = calculator.calculate(prices: prices)
        }
    }
}