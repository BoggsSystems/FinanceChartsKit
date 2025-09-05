import Foundation

public enum Timeframe: String, CaseIterable, Codable {
    case m1 = "1m"
    case m5 = "5m"
    case m15 = "15m"
    case h1 = "1h"
    case d1 = "1d"
    
    public var displayName: String {
        switch self {
        case .m1: return "1 minute"
        case .m5: return "5 minutes"
        case .m15: return "15 minutes"
        case .h1: return "1 hour"
        case .d1: return "1 day"
        }
    }
    
    public var shortDisplayName: String {
        return rawValue.uppercased()
    }
    
    public var seconds: TimeInterval {
        switch self {
        case .m1: return 60
        case .m5: return 300
        case .m15: return 900
        case .h1: return 3600
        case .d1: return 86400
        }
    }
    
    public var next: Timeframe {
        switch self {
        case .m1: return .m5
        case .m5: return .m15
        case .m15: return .h1
        case .h1: return .d1
        case .d1: return .d1
        }
    }
    
    public var previous: Timeframe {
        switch self {
        case .m1: return .m1
        case .m5: return .m1
        case .m15: return .m5
        case .h1: return .m15
        case .d1: return .h1
        }
    }
}