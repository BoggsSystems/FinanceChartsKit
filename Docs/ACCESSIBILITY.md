# Accessibility Guide

## Overview

FinanceChartsKit is designed with accessibility as a core principle, ensuring that financial data visualization is available to all users, including those with visual impairments, motor disabilities, and cognitive differences.

## Visual Accessibility

### Color-Blind Support

#### Built-in Color-Blind Safe Theme

```swift
// Use deuteranopia-safe colors
chartController.setTheme(.deuteranopia)
```

The deuteranopia theme uses blue/orange instead of red/green:
- **Up Movement**: Blue (#0066CC) 
- **Down Movement**: Orange (#CC6600)
- **Overlay Indicators**: Carefully selected non-conflicting colors

#### Multi-Modal Visual Encoding

Beyond color, the framework provides additional visual cues:

1. **Pattern Differentiation**
   ```swift
   // Bollinger bands use dashed lines
   bollingerUpperLayer.lineDashPattern = [4, 4]
   bollingerLowerLayer.lineDashPattern = [4, 4]
   ```

2. **Shape Variations**
   - Up candles: Filled rectangles
   - Down candles: Outlined rectangles (when implemented)
   - Different crosshair styles for different modes

3. **Brightness Coding**
   - Higher volume uses brighter colors
   - Recent data has higher opacity
   - Focus elements have enhanced brightness

### High Contrast Support

#### System Integration

```swift
// Respond to system accessibility settings
extension ChartController {
    private func updateForAccessibility() {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            setTheme(.highContrast)
        }
        
        if UIAccessibility.isReduceTransparencyEnabled {
            // Remove alpha blending
            theme.gridColor = theme.gridColor.withAlphaComponent(1.0)
        }
    }
}
```

#### High Contrast Theme

Future enhancement for maximum visibility:

```swift
extension Theme {
    static let highContrast = Theme(
        backgroundColor: .black,
        gridColor: .white,
        textColor: .white,
        upColor: UIColor.systemGreen,
        downColor: UIColor.systemRed,
        // ... enhanced contrast values
    )
}
```

### Large Type Support

#### Dynamic Type Integration

```swift
extension Theme {
    var adjustedForDynamicType: Theme {
        let multiplier = UIFontMetrics.default.scaledValue(for: 1.0)
        
        return Theme(
            primaryFontSize: primaryFontSize * multiplier,
            secondaryFontSize: secondaryFontSize * multiplier,
            labelFontSize: labelFontSize * multiplier,
            // ... other properties
        )
    }
}
```

#### Minimum Size Guarantees

All interactive elements meet minimum size requirements:
- **Touch Targets**: 44pt minimum (iOS guidelines)
- **Focus Areas**: 60pt minimum (tvOS guidelines)  
- **Text**: 16pt minimum at standard size

## VoiceOver Support

### Accessibility Labels

```swift
extension PriceChartView {
    private func configureAccessibility() {
        accessibilityLabel = "Stock price chart for \(controller.symbol)"
        accessibilityTraits = [.updatesFrequently, .allowsDirectInteraction]
        
        // Dynamic value updates
        accessibilityValue = generateAccessibilityDescription()
    }
    
    private func generateAccessibilityDescription() -> String {
        guard let lastCandle = controller.visibleCandles.last else {
            return "Chart data loading"
        }
        
        let direction = lastCandle.isGreen ? "up" : "down"
        let price = NumberFormatter.currency.string(from: NSNumber(value: Float(lastCandle.close))) ?? ""
        let change = NumberFormatter.percentage.string(from: NSNumber(value: Float(controller.percentChange))) ?? ""
        
        return "Current price \(price), \(direction) \(change) percent"
    }
}
```

### Custom Actions

```swift
extension ChartView {
    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        return [
            UIAccessibilityCustomAction(name: "Toggle RSI") { _ in
                self.controller?.toggleIndicator(.rsi14)
                return true
            },
            UIAccessibilityCustomAction(name: "Change Timeframe") { _ in
                self.controller?.cycleTimeframeUp()
                return true
            },
            UIAccessibilityCustomAction(name: "Reset Zoom") { _ in
                self.controller?.resetZoomAndPan()
                return true
            }
        ]
    }
}
```

### Data Navigation

For VoiceOver users, provide structured data access:

```swift
extension ChartController {
    var accessibleDataPoints: [String] {
        return visibleCandles.enumerated().map { index, candle in
            let date = DateFormatter.accessibilityDate.string(from: Date(timeIntervalSince1970: candle.timestamp))
            let price = NumberFormatter.currency.string(from: NSNumber(value: Float(candle.close))) ?? ""
            let direction = candle.isGreen ? "up" : "down"
            
            return "Data point \(index + 1): \(date), price \(price), \(direction)"
        }
    }
}
```

## Motor Accessibility

### Switch Control Support

#### Simplified Navigation

```swift
#if os(tvOS)
extension ChartView {
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]  // Direct focus to chart
    }
    
    // Simplified remote control handling
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else { return }
        
        switch press.type {
        case .select:
            // Single action: toggle crosshair
            toggleCrosshair()
        case .playPause:
            // Alternative action: same as select for motor accessibility
            toggleCrosshair()  
        default:
            super.pressesBegan(presses, with: event)
        }
    }
}
#endif
```

#### Reduced Motion

```swift
extension ChartController {
    private func configureForMotorAccessibility() {
        if UIAccessibility.isReduceMotionEnabled {
            // Disable smooth animations
            renderScheduler.setAnimationsEnabled(false)
            
            // Use instant updates instead of smooth transitions
            panAnimationDuration = 0
            zoomAnimationDuration = 0
        }
    }
}
```

### Alternative Input Methods

Support for alternative input devices:

```swift
// Support for external keyboards
extension ChartView {
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(panLeft)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(panRight)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(zoomIn)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(zoomOut)),
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(toggleCrosshair))
        ]
    }
}
```

## Cognitive Accessibility

### Simplified Interface Options

#### Minimal Mode

```swift
extension ChartController {
    var minimalMode: Bool = false {
        didSet {
            if minimalMode {
                // Hide complex indicators
                indicators = []
                overlays = []
                
                // Use simpler visual style
                setTheme(.minimal)
                
                // Larger touch targets
                increaseTouchTargets()
            }
        }
    }
}
```

#### Consistent Visual Patterns

1. **Predictable Layout**: Fixed positions for all UI elements
2. **Clear Visual Hierarchy**: Consistent font sizes and weights
3. **Minimal Cognitive Load**: Essential information only in minimal mode

### Error Prevention

#### Input Validation

```swift
extension ChartController {
    public func setZoom(_ scale: CGFloat) {
        // Validate and clamp input
        let clampedScale = max(0.1, min(10.0, scale))
        
        // Provide feedback for invalid input
        if scale != clampedScale {
            announceAccessibilityNotification("Zoom adjusted to valid range")
        }
        
        zoomScale = clampedScale
    }
}
```

#### Graceful Degradation

```swift
// Handle missing or invalid data gracefully
extension ChartController {
    func setData(_ candles: [Candle]) {
        guard !candles.isEmpty else {
            announceAccessibilityNotification("No chart data available")
            return
        }
        
        let validCandles = candles.filter { $0.high >= $0.low && $0.close > 0 }
        
        if validCandles.count != candles.count {
            announceAccessibilityNotification("Some invalid data points were filtered")
        }
        
        self.candles = validCandles
    }
}
```

## Implementation Guidelines

### Accessibility Testing

#### Automated Testing

```swift
class AccessibilityTests: XCTestCase {
    func testVoiceOverLabels() {
        let chartView = PriceChartView(controller: testController)
        
        XCTAssertNotNil(chartView.accessibilityLabel)
        XCTAssertTrue(chartView.accessibilityLabel?.contains("chart") ?? false)
    }
    
    func testContrastRatios() {
        let theme = Theme.dark
        let contrastRatio = calculateContrastRatio(
            theme.textColor, 
            theme.backgroundColor
        )
        
        XCTAssertGreaterThan(contrastRatio, 4.5, "Must meet WCAG AA standard")
    }
    
    func testMinimumTouchTargets() {
        let interactive elements = findInteractiveElements()
        
        for element in interactiveElements {
            XCTAssertGreaterThanOrEqual(element.frame.width, 44)
            XCTAssertGreaterThanOrEqual(element.frame.height, 44)
        }
    }
}
```

#### Manual Testing Checklist

- [ ] Navigate entire interface using only VoiceOver
- [ ] Test with Switch Control enabled
- [ ] Verify with Reduce Motion enabled
- [ ] Check with high contrast enabled
- [ ] Test with largest dynamic type size
- [ ] Validate with color-blind simulation tools

### Accessibility Announcements

```swift
extension ChartController {
    private func announceDataUpdate() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        let announcement = "Chart data updated. Latest price \(formattedPrice)"
        UIAccessibility.post(
            notification: .announcement,
            argument: announcement
        )
    }
    
    private func announceTimeframeChange() {
        let announcement = "Timeframe changed to \(timeframe.displayName)"
        UIAccessibility.post(
            notification: .layoutChanged,
            argument: announcement
        )
    }
}
```

### Progressive Enhancement

#### Feature Detection

```swift
extension ChartController {
    private func configureForCapabilities() {
        // Adapt interface based on user capabilities
        if UIAccessibility.isVoiceOverRunning {
            enableVoiceOverOptimizations()
        }
        
        if UIAccessibility.isSwitchControlRunning {
            enableSwitchControlOptimizations()
        }
        
        if UIAccessibility.isReduceMotionEnabled {
            disableAnimations()
        }
    }
}
```

## Future Enhancements

### Planned Accessibility Features

1. **Audio Charts**: Sonification of price data
2. **Haptic Feedback**: Tactile price movement indication
3. **Voice Control**: Navigate charts using Siri voice commands
4. **Braille Support**: Integration with refreshable Braille displays

### Research Areas

- **Cognitive Load**: Studying optimal information density
- **Motor Efficiency**: Analyzing gesture patterns for efficiency
- **Visual Perception**: Testing with various visual impairments

## Compliance Standards

### WCAG 2.1 Compliance

| Criterion | Level | Status |
|-----------|-------|--------|
| 1.1.1 Non-text Content | AA | ✅ Implemented |
| 1.4.3 Contrast (Minimum) | AA | ✅ Implemented |
| 1.4.11 Non-text Contrast | AA | ✅ Implemented |
| 2.1.1 Keyboard | AA | ✅ Implemented |
| 2.4.7 Focus Visible | AA | ✅ Implemented |
| 3.2.1 On Focus | AA | ✅ Implemented |
| 4.1.2 Name, Role, Value | AA | ✅ Implemented |

### Section 508 Compliance

The framework meets Section 508 standards for federal accessibility requirements:
- Software applications and operating systems (§ 1194.21)
- Web-based intranet and internet information (§ 1194.22)

By following these accessibility guidelines, FinanceChartsKit ensures that financial data visualization remains inclusive and available to all users, regardless of their abilities or preferred interaction methods.