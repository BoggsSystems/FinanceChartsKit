import Foundation

public final class OHLCBuilder {
    private let timeframe: Timeframe
    private var currentOHLC: OHLC?
    
    public init(timeframe: Timeframe) {
        self.timeframe = timeframe
    }
    
    public struct BuildResult {
        public let updated: Candle?
        public let appended: Candle?
    }
    
    public func ingest(_ tick: Tick) -> BuildResult {
        let bucketTimestamp = getBucketTimestamp(for: tick.timestamp)
        
        if let current = currentOHLC {
            if current.timestamp == bucketTimestamp {
                current.update(with: tick)
                return BuildResult(updated: current.toCandle(), appended: nil)
            } else {
                let completed = current.toCandle()
                currentOHLC = OHLC(timestamp: bucketTimestamp, open: tick.price)
                currentOHLC?.update(with: tick)
                return BuildResult(updated: currentOHLC?.toCandle(), appended: completed)
            }
        } else {
            currentOHLC = OHLC(timestamp: bucketTimestamp, open: tick.price)
            currentOHLC?.update(with: tick)
            return BuildResult(updated: currentOHLC?.toCandle(), appended: nil)
        }
    }
    
    public func reset() {
        currentOHLC = nil
    }
    
    private func getBucketTimestamp(for timestamp: TimeInterval) -> TimeInterval {
        let bucketSize = timeframe.seconds
        return floor(timestamp / bucketSize) * bucketSize
    }
}