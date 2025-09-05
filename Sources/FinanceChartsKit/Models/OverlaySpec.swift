import Foundation

public struct OverlaySpec: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let ema20 = OverlaySpec(rawValue: 1 << 0)
    public static let ema50 = OverlaySpec(rawValue: 1 << 1)
    public static let sma20 = OverlaySpec(rawValue: 1 << 2)
    public static let sma50 = OverlaySpec(rawValue: 1 << 3)
    public static let bollinger20 = OverlaySpec(rawValue: 1 << 4)
    
    public static let all: OverlaySpec = [.ema20, .ema50, .sma20, .sma50, .bollinger20]
    
    public var displayNames: [String] {
        var names: [String] = []
        if contains(.ema20) { names.append("EMA 20") }
        if contains(.ema50) { names.append("EMA 50") }
        if contains(.sma20) { names.append("SMA 20") }
        if contains(.sma50) { names.append("SMA 50") }
        if contains(.bollinger20) { names.append("Bollinger 20") }
        return names
    }
}

public struct IndicatorSpec: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let rsi14 = IndicatorSpec(rawValue: 1 << 0)
    public static let macd = IndicatorSpec(rawValue: 1 << 1)
    public static let stochastic = IndicatorSpec(rawValue: 1 << 2)
    
    public static let all: IndicatorSpec = [.rsi14, .macd, .stochastic]
    
    public var displayNames: [String] {
        var names: [String] = []
        if contains(.rsi14) { names.append("RSI 14") }
        if contains(.macd) { names.append("MACD") }
        if contains(.stochastic) { names.append("Stochastic") }
        return names
    }
}