# API Reference

## Overview

FinanceChartsKit provides a clean, SwiftUI-native API for embedding high-performance financial charts in tvOS applications. The architecture separates data management (`ChartController`) from presentation (`PriceChartView`).

## Core Components

### ChartController

The main controller class managing chart data and configuration.

```swift
public final class ChartController: ObservableObject {
    @Published public var symbol: String
    @Published public var timeframe: Timeframe  
    @Published public var overlays: OverlaySpec
    @Published public var indicators: IndicatorSpec
}
```

#### Data Management

```swift
// Set complete dataset (replaces existing data)
public func setData(_ candles: [Candle])

// Update the last candle (for live price updates)  
public func updateLast(_ candle: Candle)

// Append new candle (for new time periods)
public func append(_ candle: Candle)
```

#### Viewport Control

```swift
// Semantic zoom (1.0 = default, 0.5 = zoomed out, 2.0 = zoomed in)
public func setZoom(_ scale: CGFloat)

// Pan by number of bars (+/- values)
public func pan(byBars: Int)

// Show/hide crosshair at screen position
public func setCrosshair(x: CGFloat?)
```

#### Export & Utilities

```swift
// Generate UIImage snapshot
public func snapshot() -> UIImage?

// Convenience methods
public func resetZoomAndPan()
public func cycleTimeframeUp()  
public func cycleTimeframeDown()
public func toggleOverlay(_ overlay: OverlaySpec)
public func toggleIndicator(_ indicator: IndicatorSpec)
```

### PriceChartView

SwiftUI view wrapper for the chart.

```swift
public struct PriceChartView: View {
    public init(controller: ChartController)
    public var body: some View
}
```

#### Basic Usage

```swift
struct ContentView: View {
    @StateObject private var chartController = ChartController()
    
    var body: some View {
        PriceChartView(controller: chartController)
            .onAppear {
                setupChart()
            }
    }
    
    private func setupChart() {
        chartController.symbol = "AAPL"
        chartController.timeframe = .h1
        chartController.setData(candleData)
    }
}
```

## Data Models

### Candle

Primary data structure for OHLCV data.

```swift
public struct Candle: Equatable, Codable {
    public let timestamp: TimeInterval
    public let open: CGFloat
    public let high: CGFloat  
    public let low: CGFloat
    public let close: CGFloat
    public let volume: CGFloat
    
    // Convenience properties
    public var isGreen: Bool
    public var bodyHigh: CGFloat
    public var bodyLow: CGFloat
    public var range: CGFloat
    public var bodyHeight: CGFloat
}
```

### Timeframe

Enumeration for chart time granularity.

```swift
public enum Timeframe: String, CaseIterable {
    case m1 = "1m"    // 1 minute
    case m5 = "5m"    // 5 minutes  
    case m15 = "15m"  // 15 minutes
    case h1 = "1h"    // 1 hour
    case d1 = "1d"    // 1 day
    
    public var seconds: TimeInterval
    public var displayName: String
    public var next: Timeframe
    public var previous: Timeframe
}
```

### OverlaySpec

Option set for price overlays.

```swift
public struct OverlaySpec: OptionSet {
    public static let ema20 = OverlaySpec(rawValue: 1 << 0)
    public static let ema50 = OverlaySpec(rawValue: 1 << 1) 
    public static let sma20 = OverlaySpec(rawValue: 1 << 2)
    public static let sma50 = OverlaySpec(rawValue: 1 << 3)
    public static let bollinger20 = OverlaySpec(rawValue: 1 << 4)
    
    public var displayNames: [String]
}
```

### IndicatorSpec  

Option set for technical indicators.

```swift
public struct IndicatorSpec: OptionSet {
    public static let rsi14 = IndicatorSpec(rawValue: 1 << 0)
    public static let macd = IndicatorSpec(rawValue: 1 << 1)
    public static let stochastic = IndicatorSpec(rawValue: 1 << 2)
    
    public var displayNames: [String]
}
```

## Live Data Integration

### OHLCBuilder

Utility for aggregating ticks into OHLC candles.

```swift
public struct Tick {
    public let timestamp: TimeInterval
    public let price: CGFloat
    public let volume: CGFloat
}

public final class OHLCBuilder {
    public init(timeframe: Timeframe)
    
    public struct BuildResult {
        public let updated: Candle?    // Modified existing candle
        public let appended: Candle?   // New completed candle  
    }
    
    public func ingest(_ tick: Tick) -> BuildResult
    public func reset()
}
```

#### Live Data Example

```swift
class LiveDataManager {
    private let ohlcBuilder = OHLCBuilder(timeframe: .m1)
    private let chartController: ChartController
    
    func handleTick(_ tick: Tick) {
        let result = ohlcBuilder.ingest(tick)
        
        if let updated = result.updated {
            chartController.updateLast(updated)
        }
        
        if let appended = result.appended {
            chartController.append(appended)
        }
    }
}
```

## theming

### Theme  

Customizable color and typography settings.

```swift
public struct Theme {
    public let backgroundColor: UIColor
    public let gridColor: UIColor
    public let textColor: UIColor
    public let upColor: UIColor
    public let downColor: UIColor
    public let volumeColor: UIColor
    public let crosshairColor: UIColor
    public let overlayColors: [UIColor]
    public let indicatorColors: [UIColor]
    
    public let primaryFontSize: CGFloat
    public let secondaryFontSize: CGFloat
    public let labelFontSize: CGFloat
    
    public static let dark: Theme
    public static let deuteranopia: Theme  // Color-blind friendly
}
```

#### Custom Theme Example

```swift
let customTheme = Theme(
    backgroundColor: .black,
    gridColor: .gray,
    textColor: .white,
    upColor: .systemGreen,
    downColor: .systemRed,
    // ... other properties
)

chartController.setTheme(customTheme)
```

## tvOS Integration

### Remote Navigation

The chart automatically handles Apple TV remote input:

| Input | Action |
|-------|--------|
| Left/Right | Pan by bars (accelerates on hold) |
| Up/Down | Cycle timeframe |
| Select | Toggle crosshair |
| Play/Pause | Show/hide crosshair |
| Menu | Clear crosshair/go back |
| Long Press | Quick palette (if delegate set) |

### Focus Management

```swift
// Chart view is automatically focusable
PriceChartView(controller: chartController)
    .focusable()
```

## Advanced Usage

### Custom Indicators  

For future expansion, indicators follow this pattern:

```swift
protocol IndicatorCalculator {
    associatedtype Input
    associatedtype Output
    
    func calculate(input: [Input]) -> [Output?]
    func reset()
}
```

### Performance Monitoring

```swift
// Track performance metrics
chartController.setPerformanceDelegate(self)

extension MyView: ChartPerformanceDelegate {
    func chartDidDropFrame(_ frameTime: TimeInterval) {
        print("Frame drop: \(frameTime * 1000)ms")
    }
    
    func chartMemoryUsage(_ bytes: Int) {
        print("Memory: \(bytes / 1024 / 1024)MB")
    }
}
```

### Accessibility Support

```swift
PriceChartView(controller: chartController)
    .accessibilityLabel("Stock price chart for \(controller.symbol)")
    .accessibilityValue("Price: \(currentPrice), Change: \(percentChange)%")
```

## Error Handling

### Connection States

```swift
// Indicate connection status
chartController.setConnectionStatus(false)  // Shows "Reconnecting..."
```

### Data Validation

The framework handles common data issues gracefully:
- Missing or invalid timestamps
- Negative/zero prices (clamped to minimum values)
- Insufficient data for indicators (returns nil values)
- Out-of-order data (automatically sorted)

## Integration Patterns

### WebSocket Integration

```swift
class WebSocketManager: ObservableObject {
    private let chartController: ChartController
    private let ohlcBuilder: OHLCBuilder
    
    func onWebSocketMessage(_ data: Data) {
        guard let tick = parseTick(data) else { return }
        
        let result = ohlcBuilder.ingest(tick)
        
        if let updated = result.updated {
            chartController.updateLast(updated)
        }
        
        if let completed = result.appended {
            chartController.append(completed)
        }
    }
}
```

### SwiftUI State Management

```swift
struct TradingView: View {
    @StateObject private var chartController = ChartController()
    @State private var selectedSymbol = "AAPL"
    
    var body: some View {
        VStack {
            symbolPicker
            PriceChartView(controller: chartController)
            controlPanel
        }
        .onChange(of: selectedSymbol) { symbol in
            loadData(for: symbol)
        }
    }
}
```

## Best Practices

1. **Data Loading**: Load data asynchronously and update controller on main thread
2. **Memory Management**: Use `setData()` for full refreshes, `updateLast()` for live updates  
3. **Performance**: Enable only needed overlays/indicators
4. **Accessibility**: Provide meaningful labels and values
5. **Error Handling**: Handle network failures gracefully with connection status updates
6. **Testing**: Use provided test data generators for unit tests