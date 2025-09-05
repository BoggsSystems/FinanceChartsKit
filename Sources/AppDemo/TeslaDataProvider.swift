import Foundation
import FinanceChartsKit

struct TeslaDataProvider {
    static let teslaOHLCData: [Candle] = {
        guard let url = Bundle.module.url(forResource: "tesla_ohlc", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return generateSampleData()
        }
        
        do {
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            return jsonData?.compactMap { dict in
                guard let timestamp = dict["timestamp"] as? TimeInterval,
                      let open = dict["open"] as? Double,
                      let high = dict["high"] as? Double,
                      let low = dict["low"] as? Double,
                      let close = dict["close"] as? Double,
                      let volume = dict["volume"] as? Double else {
                    return nil
                }
                
                return Candle(
                    timestamp: timestamp,
                    open: CGFloat(open),
                    high: CGFloat(high),
                    low: CGFloat(low),
                    close: CGFloat(close),
                    volume: CGFloat(volume)
                )
            } ?? generateSampleData()
        } catch {
            return generateSampleData()
        }
    }()
    
    static func generateSampleData() -> [Candle] {
        var candles: [Candle] = []
        let basePrice: CGFloat = 250.0
        let baseTimestamp: TimeInterval = Date().timeIntervalSince1970 - (1500 * 3600)
        
        var currentPrice = basePrice
        
        for i in 0..<1500 {
            let timestamp = baseTimestamp + TimeInterval(i * 3600)
            let volatility: CGFloat = 0.02
            
            let priceChange = CGFloat.random(in: -volatility...volatility) * currentPrice
            let open = currentPrice
            let close = currentPrice + priceChange
            
            let highOffset = CGFloat.random(in: 0...0.01) * currentPrice
            let lowOffset = CGFloat.random(in: 0...0.01) * currentPrice
            
            let high = max(open, close) + highOffset
            let low = min(open, close) - lowOffset
            
            let volume = CGFloat.random(in: 20000000...80000000)
            
            let candle = Candle(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
            
            candles.append(candle)
            currentPrice = close
        }
        
        return candles
    }
    
    static func generateRandomTick(basedOn lastCandle: Candle) -> Tick {
        let priceChange = CGFloat.random(in: -1.0...1.0)
        let newPrice = max(1.0, lastCandle.close + priceChange)
        let volume = CGFloat.random(in: 100...1000)
        
        return Tick(
            timestamp: Date().timeIntervalSince1970,
            price: newPrice,
            volume: volume
        )
    }
}