import Foundation

public struct Tick: Equatable, Codable {
    public let timestamp: TimeInterval
    public let price: CGFloat
    public let volume: CGFloat
    
    public init(timestamp: TimeInterval, price: CGFloat, volume: CGFloat) {
        self.timestamp = timestamp
        self.price = price
        self.volume = volume
    }
}

public struct OHLC: Equatable, Codable {
    public var open: CGFloat
    public var high: CGFloat
    public var low: CGFloat
    public var close: CGFloat
    public var volume: CGFloat
    public var timestamp: TimeInterval
    
    public init(timestamp: TimeInterval, open: CGFloat) {
        self.timestamp = timestamp
        self.open = open
        self.high = open
        self.low = open
        self.close = open
        self.volume = 0
    }
    
    public mutating func update(with tick: Tick) {
        high = max(high, tick.price)
        low = min(low, tick.price)
        close = tick.price
        volume += tick.volume
    }
    
    public func toCandle() -> Candle {
        return Candle(
            timestamp: timestamp,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume
        )
    }
}