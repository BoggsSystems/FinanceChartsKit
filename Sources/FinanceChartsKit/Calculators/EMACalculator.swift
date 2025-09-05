import Foundation

public final class EMACalculator {
    private let period: Int
    private let multiplier: CGFloat
    private var initialized = false
    private var previousEMA: CGFloat = 0
    
    public init(period: Int) {
        self.period = period
        self.multiplier = 2.0 / CGFloat(period + 1)
    }
    
    public func calculate(prices: [CGFloat]) -> [CGFloat?] {
        guard !prices.isEmpty else { return [] }
        
        var results: [CGFloat?] = Array(repeating: nil, count: prices.count)
        
        if prices.count >= period {
            let smaSum = prices.prefix(period).reduce(0, +)
            let sma = smaSum / CGFloat(period)
            results[period - 1] = sma
            previousEMA = sma
            initialized = true
        }
        
        for i in period..<prices.count {
            let ema = (prices[i] - previousEMA) * multiplier + previousEMA
            results[i] = ema
            previousEMA = ema
        }
        
        return results
    }
    
    public func calculate(prices: [CGFloat], startingEMA: CGFloat?) -> [CGFloat?] {
        if let startingEMA = startingEMA {
            previousEMA = startingEMA
            initialized = true
        }
        return calculate(prices: prices)
    }
    
    public func reset() {
        initialized = false
        previousEMA = 0
    }
}

public final class SMACalculator {
    private let period: Int
    
    public init(period: Int) {
        self.period = period
    }
    
    public func calculate(prices: [CGFloat]) -> [CGFloat?] {
        guard prices.count >= period else { return Array(repeating: nil, count: prices.count) }
        
        var results: [CGFloat?] = Array(repeating: nil, count: prices.count)
        
        for i in (period - 1)..<prices.count {
            let startIndex = i - period + 1
            let endIndex = i + 1
            let sum = prices[startIndex..<endIndex].reduce(0, +)
            results[i] = sum / CGFloat(period)
        }
        
        return results
    }
}

public final class BollingerBandsCalculator {
    private let period: Int
    private let standardDeviations: CGFloat
    private let smaCalculator: SMACalculator
    
    public init(period: Int = 20, standardDeviations: CGFloat = 2.0) {
        self.period = period
        self.standardDeviations = standardDeviations
        self.smaCalculator = SMACalculator(period: period)
    }
    
    public struct BollingerBands {
        public let upper: CGFloat?
        public let middle: CGFloat?
        public let lower: CGFloat?
    }
    
    public func calculate(prices: [CGFloat]) -> [BollingerBands] {
        let smaValues = smaCalculator.calculate(prices: prices)
        var results: [BollingerBands] = []
        
        for i in 0..<prices.count {
            guard let sma = smaValues[i], i >= period - 1 else {
                results.append(BollingerBands(upper: nil, middle: nil, lower: nil))
                continue
            }
            
            let startIndex = i - period + 1
            let endIndex = i + 1
            let slice = Array(prices[startIndex..<endIndex])
            
            let variance = slice.reduce(0) { sum, price in
                let diff = price - sma
                return sum + diff * diff
            } / CGFloat(period)
            
            let standardDeviation = sqrt(variance)
            let upper = sma + standardDeviations * standardDeviation
            let lower = sma - standardDeviations * standardDeviation
            
            results.append(BollingerBands(upper: upper, middle: sma, lower: lower))
        }
        
        return results
    }
}