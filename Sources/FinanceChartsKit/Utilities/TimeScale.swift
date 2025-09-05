import Foundation

public final class TimeScale {
    private let timeframe: Timeframe
    
    public init(timeframe: Timeframe) {
        self.timeframe = timeframe
    }
    
    public func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        
        switch timeframe {
        case .m1, .m5, .m15:
            formatter.dateFormat = "HH:mm"
        case .h1:
            formatter.dateFormat = "HH:mm"
        case .d1:
            formatter.dateFormat = "MMM dd"
        }
        
        return formatter.string(from: date)
    }
    
    public func getGridInterval(for visibleRange: TimeInterval) -> TimeInterval {
        switch timeframe {
        case .m1:
            if visibleRange <= 3600 { return 300 }
            if visibleRange <= 7200 { return 600 }
            return 1800
        case .m5:
            if visibleRange <= 3600 { return 900 }
            if visibleRange <= 14400 { return 1800 }
            return 3600
        case .m15:
            if visibleRange <= 14400 { return 3600 }
            return 7200
        case .h1:
            if visibleRange <= 86400 { return 14400 }
            return 43200
        case .d1:
            if visibleRange <= 604800 { return 86400 }
            return 604800
        }
    }
    
    public func getOptimalCandleWidth(containerWidth: CGFloat, visibleCandles: Int) -> CGFloat {
        let minWidth: CGFloat = 1.0
        let maxWidth: CGFloat = 20.0
        let idealWidth = containerWidth / CGFloat(visibleCandles)
        
        return max(minWidth, min(maxWidth, idealWidth))
    }
    
    public func shouldShowCandlesticks(candleWidth: CGFloat) -> Bool {
        return candleWidth >= 2.0
    }
}