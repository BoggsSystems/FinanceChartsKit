# FinanceChartsKit Architecture

## Overview

FinanceChartsKit is a high-performance, tvOS-optimized charting framework built with SwiftUI as a host shell and Core Animation/Core Graphics for rendering. The architecture prioritizes 60fps performance, zero jank, and native Apple TV user experience.

## Design Principles

1. **Performance First**: 60fps rendering with ≤1.5ms draw time @ 4K
2. **Modular Architecture**: Clean separation of concerns
3. **tvOS Native**: Built for Apple TV remote navigation patterns
4. **Memory Efficient**: Zero per-frame allocations on hot paths
5. **Extensible**: Easy to add new indicators and chart types

## Scene Graph Architecture

```
PriceChartView (SwiftUI)
└── ChartView (UIView)
    ├── PriceLayer (CALayer)
    │   ├── CandlestickLayer
    │   └── VolumeLayer
    ├── OverlayLayer (CALayer)
    │   ├── EMALayer
    │   ├── SMALayer
    │   └── BollingerLayer
    ├── IndicatorPaneLayer (CALayer)
    │   └── RSILayer
    ├── CrosshairLayer (CALayer)
    │   ├── VerticalRuleLayer
    │   ├── HorizontalRuleLayer
    │   └── CalloutLayer
    └── HUDLayer (CALayer)
        ├── TickerLabel (CATextLayer)
        ├── PriceLabel (CATextLayer)
        ├── PercentLabel (CATextLayer)
        └── TimeframeLabel (CATextLayer)
```

## Core Components

### Data Models

- **Candle**: OHLCV data with timestamp
- **Timeframe**: Enum for time granularity (1m, 5m, 15m, 1H, 1D)
- **OverlaySpec**: Option set for overlay indicators
- **IndicatorSpec**: Option set for bottom pane indicators

### Rendering Pipeline

1. **Data Preparation**: Downsampling, calculations
2. **Coordinate Transform**: Price/time → screen coordinates
3. **Path Generation**: Create CGPaths for efficient drawing
4. **Layer Updates**: Update only changed layers
5. **Composition**: Hardware-accelerated layer composition

### Controllers

- **ChartController**: Main API controller managing data and view state
- **RenderScheduler**: CADisplayLink-based update throttling
- **FocusController**: tvOS remote navigation handling

### Utilities

- **Downsampler**: LTTB algorithm for optimal visual representation
- **TimeScale**: Time axis calculations and formatting
- **RSICalculator**: Relative Strength Index computation
- **EMACalculator**: Exponential Moving Average computation
- **Theme**: Color schemes and typography

## Data Flow

```
External Data Source
    ↓
ChartController
    ↓
Data Processing (RSI, EMA calculations)
    ↓
Coordinate Transformation
    ↓
Path Generation
    ↓
Layer Updates
    ↓
Render (60fps)
```

## Performance Optimizations

### Drawing Optimizations

1. **Single Pass Rendering**: All candles drawn in one CGContext pass
2. **Path Reuse**: CGMutablePath objects cached and reused
3. **Dirty Rectangles**: Only redraw changed regions
4. **Implicit Animation Disable**: `CATransaction.setDisableActions(true)`

### Memory Management

1. **Object Pooling**: Reuse temporary objects
2. **Lazy Loading**: Calculate indicators on demand
3. **Viewport Culling**: Only process visible data
4. **Buffer Reuse**: Reuse calculation buffers

### Data Processing

1. **Downsampling**: LTTB algorithm reduces data points while preserving extremes
2. **Incremental Updates**: Only recalculate changed portions
3. **Background Processing**: Heavy calculations on background queue
4. **Result Caching**: Cache expensive calculations

## Focus Map (tvOS)

```
Chart Container
├── Left/Right: Pan by bars (accelerating on hold)
├── Up/Down: Cycle timeframe
├── Select: Toggle crosshair
├── Play/Pause: Show/hide crosshair
├── Menu: Back/close overlays
└── Long Press: Quick palette (host callback)
```

## Threading Model

- **Main Thread**: UI updates, layer composition
- **Background Queue**: Data processing, calculations
- **Display Link**: Render scheduling (30-60fps adaptive)

## Extension Points

### Adding New Indicators

1. Create calculator class conforming to `IndicatorCalculator`
2. Add to `IndicatorSpec` option set
3. Implement rendering in appropriate layer
4. Add to focus navigation if interactive

### Adding Chart Types

1. Create new layer subclass
2. Implement drawing methods
3. Add to controller's layer management
4. Update coordinate transformation if needed

## Testing Strategy

- **Unit Tests**: Calculation accuracy, data transformations
- **Performance Tests**: Frame time measurements, memory profiling
- **Snapshot Tests**: Visual regression testing
- **UI Tests**: Focus navigation, interaction patterns

## Dependencies

- **Foundation**: Core data types
- **SwiftUI**: Host view wrapper
- **UIKit**: Base view infrastructure
- **CoreAnimation**: High-performance rendering
- **CoreGraphics**: Path generation and drawing
- **QuartzCore**: Display link and timing

## Future Enhancements

- **Additional Indicators**: MACD, Stochastic, Williams %R
- **Chart Types**: Area charts, Heikin-Ashi candles
- **Advanced Features**: Drawing tools, alerts visualization
- **Accessibility**: VoiceOver support, high contrast mode