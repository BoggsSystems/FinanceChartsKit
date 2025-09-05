# Performance Guide

## Performance Targets

FinanceChartsKit is designed to meet strict performance requirements for smooth tvOS operation:

- **Frame Rate**: Sustained 60fps during all interactions
- **Draw Time**: ≤1.5ms per frame @ 4K resolution
- **Memory**: Stable memory usage with no per-frame allocations
- **Data Scale**: Support 3,000-5,000 visible candles without stutter
- **Live Updates**: 10-15Hz real-time updates without frame drops

## Rendering Performance

### Drawing Optimizations

1. **Single Pass Rendering**
   - All candles drawn in one CGContext pass
   - Avoids layer-per-candle overhead
   - Batch path operations for efficiency

2. **Path Reuse Strategy**
   ```swift
   private let reusablePath = CGMutablePath()
   
   func updateLayer() {
       reusablePath.removeAllPoints()  // Reuse instead of allocate
       // Build path...
       layer.path = reusablePath
   }
   ```

3. **Selective Layer Updates**
   - Only redraw layers when data changes
   - Use dirty flags to track update needs
   - Disable implicit animations during updates

4. **Coordinate Transformation Caching**
   - Cache price-to-screen coordinate mappings
   - Recalculate only on viewport changes
   - Pre-compute common values

### Downsampling Strategy

Data reduction is crucial for maintaining performance with large datasets:

#### LTTB (Largest Triangle Three Buckets)
- Preserves visual extremes and trends
- Reduces 10,000 points to 1,000 while maintaining chart fidelity
- ~2ms processing time for typical datasets

#### Min/Max Binning
- Alternative for pixel-perfect representation
- One min/max pair per pixel column
- Faster processing but less trend preservation

#### Automatic Switching
```swift
let pointsPerPixel = dataPoints / Int(viewWidth)
if pointsPerPixel > 2 {
    // Use LTTB for trend preservation
    downsampledData = Downsampler.lttb(data: candles, targetPoints: Int(viewWidth))
} else {
    // Use min/max for pixel accuracy  
    downsampledData = Downsampler.minMaxDownsample(data: candles, targetPixelWidth: Int(viewWidth))
}
```

## Memory Management

### Zero-Allocation Hot Paths

Critical for maintaining 60fps:

```swift
class RenderLayer {
    // Pre-allocated buffers
    private var coordinateBuffer: [CGPoint] = []
    private let reusablePath = CGMutablePath()
    
    func update() {
        coordinateBuffer.removeAll(keepingCapacity: true)  // Keep capacity
        coordinateBuffer.reserveCapacity(expectedPoints)    // Avoid reallocations
        
        // Fill buffer without allocations
        for candle in candles {
            coordinateBuffer.append(transform(candle))
        }
    }
}
```

### Object Pool Pattern

For frequently created/destroyed objects:

```swift
class CalculationBufferPool {
    private var availableBuffers: [CalculationBuffer] = []
    
    func borrow() -> CalculationBuffer {
        return availableBuffers.popLast() ?? CalculationBuffer()
    }
    
    func return(_ buffer: CalculationBuffer) {
        buffer.reset()
        availableBuffers.append(buffer)
    }
}
```

## Threading Strategy

### Background Processing

Heavy calculations moved off main thread:

```swift
class ChartController {
    private let calculationQueue = DispatchQueue(label: "calculations", qos: .userInitiated)
    
    func updateIndicators() {
        calculationQueue.async { [weak self] in
            let rsiValues = self?.calculateRSI()
            let emaValues = self?.calculateEMA()
            
            DispatchQueue.main.async {
                self?.updateLayers(rsi: rsiValues, ema: emaValues)
            }
        }
    }
}
```

### Main Thread Responsibilities

Keep main thread focused on UI:
- Layer updates and composition
- User interaction handling  
- Display link callbacks
- Coordinate transformations (fast operations)

## Performance Budgets

### Per-Frame Budget (16.67ms @ 60fps)

| Operation | Budget | Typical |
|-----------|--------|---------|
| Data Processing | 2ms | 0.5ms |
| Coordinate Transform | 1ms | 0.3ms |
| Path Generation | 3ms | 1.2ms |
| Layer Updates | 2ms | 0.8ms |
| Composition | 8ms | 4-6ms |
| **Total** | **16ms** | **7-9ms** |

### Memory Budget

| Component | Budget | Typical |
|-----------|--------|---------|
| Base Framework | 5MB | 3MB |
| Data (3K candles) | 2MB | 1.5MB |
| Render Buffers | 3MB | 2MB |
| Layer Cache | 5MB | 3MB |
| **Total** | **15MB** | **9.5MB** |

## Profiling and Monitoring

### Performance Metrics

Track these key metrics:

```swift
class PerformanceMonitor {
    private var frameStartTime: CFTimeInterval = 0
    
    func startFrame() {
        frameStartTime = CACurrentMediaTime()
    }
    
    func endFrame() {
        let frameTime = CACurrentMediaTime() - frameStartTime
        if frameTime > 0.0167 {  // >16.67ms = dropped frame
            print("Frame drop: \(frameTime * 1000)ms")
        }
    }
}
```

### Instruments Integration

Use these Instruments templates:

1. **Time Profiler**: Identify CPU hotspots
2. **Core Animation**: Layer performance analysis  
3. **Allocations**: Memory leak detection
4. **GPU Frame Capture**: Metal performance (if using Metal)

### Performance Testing

Automated performance tests:

```swift
func testRenderPerformanceWith3000Candles() {
    let candles = generateTestData(count: 3000)
    
    measure {
        chartController.setData(candles)
    }
    
    // Assert < 1.5ms per frame
}
```

## Optimization Guidelines

### DO
- Pre-allocate buffers and reuse them
- Use dirty flags to avoid unnecessary updates
- Batch drawing operations  
- Profile regularly with realistic data
- Cache expensive calculations
- Use appropriate data structures (arrays for iteration, dictionaries for lookup)

### DON'T  
- Allocate objects in render loops
- Create layers per data point
- Update layers every frame unnecessarily
- Block main thread with heavy calculations
- Use overly complex data structures
- Enable implicit animations during data updates

### tvOS-Specific Optimizations

1. **Focus System Integration**
   ```swift
   override var preferredFocusEnvironments: [UIFocusEnvironment] {
       return [chartView]  // Direct focus to chart
   }
   ```

2. **Remote Input Debouncing**
   ```swift
   private var panTimer: Timer?
   
   func handleRemoteInput() {
       panTimer?.invalidate()
       panTimer = Timer.scheduledTimer(withTimeInterval: 0.1) {
           // Coalesce rapid inputs
       }
   }
   ```

3. **Memory Pressure Handling**
   ```swift
   override func didReceiveMemoryWarning() {
       clearRenderCache()
       downsampleAggressively()
   }
   ```

## Troubleshooting Common Issues

### Frame Drops
- Check Instruments Time Profiler
- Verify no main thread blocking
- Review memory allocations per frame

### High Memory Usage  
- Enable malloc stack logging
- Check for retained render buffers
- Verify proper downsampling

### Slow Startup
- Profile asset loading
- Check data parsing performance  
- Consider lazy initialization

### Poor Interaction Response
- Reduce pan/zoom calculation overhead
- Implement input coalescing
- Use appropriate focus update rates