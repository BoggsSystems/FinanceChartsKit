import Foundation

public struct Candle: Equatable, Codable {
    public let timestamp: TimeInterval
    public let open: CGFloat
    public let high: CGFloat
    public let low: CGFloat
    public let close: CGFloat
    public let volume: CGFloat
    
    public init(timestamp: TimeInterval, open: CGFloat, high: CGFloat, low: CGFloat, close: CGFloat, volume: CGFloat) {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
    
    public var isGreen: Bool {
        return close >= open
    }
    
    public var bodyHigh: CGFloat {
        return max(open, close)
    }
    
    public var bodyLow: CGFloat {
        return min(open, close)
    }
    
    public var range: CGFloat {
        return high - low
    }
    
    public var bodyHeight: CGFloat {
        return abs(close - open)
    }
}