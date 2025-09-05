import Foundation

public final class RSICalculator {
    private let period: Int
    private var gains: [CGFloat] = []
    private var losses: [CGFloat] = []
    private var avgGain: CGFloat = 0
    private var avgLoss: CGFloat = 0
    private var initialized = false
    
    public init(period: Int = 14) {
        self.period = period
    }
    
    public func calculate(prices: [CGFloat]) -> [CGFloat?] {
        guard prices.count >= period + 1 else { return Array(repeating: nil, count: prices.count) }
        
        var results: [CGFloat?] = Array(repeating: nil, count: prices.count)
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i - 1]
            let gain = max(change, 0)
            let loss = max(-change, 0)
            
            gains.append(gain)
            losses.append(loss)
            
            if gains.count > period {
                gains.removeFirst()
                losses.removeFirst()
            }
            
            if gains.count == period {
                if !initialized {
                    avgGain = gains.reduce(0, +) / CGFloat(period)
                    avgLoss = losses.reduce(0, +) / CGFloat(period)
                    initialized = true
                } else {
                    avgGain = (avgGain * CGFloat(period - 1) + gain) / CGFloat(period)
                    avgLoss = (avgLoss * CGFloat(period - 1) + loss) / CGFloat(period)
                }
                
                let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
                let rsi = 100 - (100 / (1 + rs))
                results[i] = rsi
            }
        }
        
        return results
    }
    
    public func reset() {
        gains.removeAll()
        losses.removeAll()
        avgGain = 0
        avgLoss = 0
        initialized = false
    }
}