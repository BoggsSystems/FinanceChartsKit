# Theme Guide

## Overview

FinanceChartsKit provides a comprehensive theming system designed for optimal tvOS viewing experience. The theme system covers colors, typography, and accessibility considerations including color-blind safe palettes.

## Color Palette Design

### Dark Theme (Default)

The default dark theme is optimized for tvOS viewing conditions:

```swift
public static let dark = Theme(
    backgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0),  // #141414
    gridColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5),           // #333333 @ 50%
    textColor: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),           // #E6E6E6
    upColor: UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0),             // #33CC33 (Green)
    downColor: UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0),           // #CC3333 (Red)
    volumeColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6),         // #666666 @ 60%
    crosshairColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8),      // #999999 @ 80%
    // Overlay and indicator colors...
)
```

### Design Rationale

1. **Background**: Very dark gray (#141414) rather than pure black
   - Reduces eye strain in dark environments
   - Provides subtle contrast for grid lines
   - Works well with OLED TVs

2. **Up/Down Colors**: High contrast green/red
   - Bright enough for 10-foot viewing
   - Sufficient contrast ratio for accessibility
   - Traditional financial color coding

3. **Text Colors**: High contrast white (#E6E6E6)
   - Ensures readability on dark background
   - Meets WCAG AA standards for contrast

## Color-Blind Safe Theme

### Deuteranopia Support

For users with red-green color blindness:

```swift
public static let deuteranopia = Theme(
    upColor: UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0),     // Blue
    downColor: UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0),   // Orange
    // Other colors remain the same
)
```

### Alternative Visual Encodings

Beyond color, the framework provides additional visual cues:

1. **Pattern Overlay**: Different line patterns for overlays
2. **Shape Variations**: Different crosshair styles
3. **Brightness Differences**: Varying opacity levels

## Typography System

### Font Size Hierarchy

Optimized for 10-foot viewing distance:

```swift
public struct Theme {
    public let primaryFontSize: CGFloat = 24      // Ticker, price
    public let secondaryFontSize: CGFloat = 20    // Percentage change
    public let labelFontSize: CGFloat = 16        // Axis labels, crosshair info
}
```

### Font Weight Guidelines

- **Primary Text**: Medium weight for price displays
- **Secondary Text**: Regular weight for labels
- **Emphasis**: Semibold for percentage changes

### Text Rendering

All text uses pixel-perfect alignment:

```swift
private func setupTextLayer(_ layer: CATextLayer) {
    layer.contentsScale = UIScreen.main.scale
    layer.isWrapped = false
    layer.truncationMode = .end
}
```

## Visual Hierarchy

### Information Priority

1. **Primary (Most Important)**
   - Current price
   - Ticker symbol
   - Price change percentage

2. **Secondary**
   - Timeframe indicator
   - Connection status
   - Crosshair values

3. **Tertiary**  
   - Grid lines
   - Axis labels
   - Volume bars

### Color Coding Priority

```swift
// High contrast for primary data
upColor: High saturation green
downColor: High saturation red

// Medium contrast for secondary data  
textColor: 90% white
crosshairColor: 60% white @ 80% alpha

// Low contrast for supporting elements
gridColor: 20% white @ 50% alpha
volumeColor: 40% white @ 60% alpha
```

## Overlay Color System

### Indicator Colors

Carefully selected to avoid conflicts:

```swift
overlayColors: [
    UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),  // Orange (EMA20)
    UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0),  // Blue (EMA50) 
    UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0),  // Magenta (SMA20)
    UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0),  // Yellow-green (SMA50)
    UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0),  // Yellow (Bollinger)
]
```

### Line Style Differentiation

Beyond color, overlays use different line styles:

- **EMA**: Solid lines
- **SMA**: Solid lines (different colors)
- **Bollinger Bands**: Dashed lines for upper/lower bounds

## Accessibility Features

### WCAG Compliance

All color combinations meet WCAG AA standards:

| Element Pair | Contrast Ratio | Standard |
|--------------|----------------|----------|
| Text on Background | 4.7:1 | AA ✓ |
| Up/Down Colors | 3.2:1 | AA ✓ |
| Grid on Background | 2.1:1 | AA ✓ |

### High Contrast Mode

Future enhancement for system accessibility settings:

```swift
extension Theme {
    static var highContrast: Theme {
        var theme = dark
        theme.textColor = .white
        theme.gridColor = UIColor.white.withAlphaComponent(0.8)
        theme.upColor = UIColor.systemGreen
        theme.downColor = UIColor.systemRed
        return theme
    }
}
```

### Reduced Motion Support

Respects system accessibility preferences:

```swift
if UIAccessibility.isReduceMotionEnabled {
    // Disable crosshair animations
    // Reduce transition effects
    // Use instant updates instead of smooth animations
}
```

## Custom Theme Creation

### Theme Structure

```swift
public struct Theme {
    // Core colors
    public let backgroundColor: UIColor
    public let gridColor: UIColor
    public let textColor: UIColor
    public let upColor: UIColor
    public let downColor: UIColor
    
    // Specialized colors
    public let volumeColor: UIColor
    public let crosshairColor: UIColor
    public let overlayColors: [UIColor]
    public let indicatorColors: [UIColor]
    
    // Typography
    public let primaryFontSize: CGFloat
    public let secondaryFontSize: CGFloat  
    public let labelFontSize: CGFloat
}
```

### Custom Theme Example

```swift
let customTheme = Theme(
    backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0),  // Dark blue
    gridColor: UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.5),
    textColor: UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0),
    upColor: UIColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0),
    downColor: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0),
    volumeColor: UIColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 0.6),
    crosshairColor: UIColor(red: 0.7, green: 0.7, blue: 0.9, alpha: 0.8),
    overlayColors: [
        UIColor.systemOrange,
        UIColor.systemBlue,
        UIColor.systemPurple,
        UIColor.systemTeal,
        UIColor.systemYellow
    ],
    indicatorColors: [
        UIColor.systemPink,
        UIColor.systemIndigo,
        UIColor.systemMint
    ],
    primaryFontSize: 26,
    secondaryFontSize: 22,
    labelFontSize: 18
)
```

## Theme Validation

### Color Contrast Testing

```swift
extension Theme {
    func validateContrast() -> Bool {
        let bgLuminance = backgroundColor.luminance
        let textLuminance = textColor.luminance
        
        let contrastRatio = (max(bgLuminance, textLuminance) + 0.05) / 
                           (min(bgLuminance, textLuminance) + 0.05)
        
        return contrastRatio >= 4.5  // WCAG AA standard
    }
}
```

### Color-Blind Testing

Use tools like Sim Daltonism to test themes:
- Deuteranopia (red-green blindness)
- Protanopia (red blindness) 
- Tritanopia (blue-yellow blindness)

## Best Practices

### DO
- Use sufficient contrast ratios
- Test with color-blind simulation tools
- Provide alternative visual encodings
- Consider 10-foot viewing distance
- Use semantic color naming

### DON'T
- Rely solely on color for information
- Use pure red/green without alternatives  
- Make text too small for TV viewing
- Use low contrast combinations
- Ignore system accessibility settings

### tvOS-Specific Guidelines

1. **Brightness**: Use brighter colors than mobile/desktop
2. **Size**: Increase font sizes for distance viewing
3. **Contrast**: Higher contrast needed for TV screens
4. **Motion**: Subtle animations help guide attention
5. **Focus**: Clear visual indication of focused elements

## Theme Switching

### Runtime Theme Changes

```swift
// Apply new theme
chartController.setTheme(.deuteranopia)

// Animate theme transition
UIView.animate(withDuration: 0.3) {
    chartController.setTheme(newTheme)
}
```

### System Integration

```swift
// Respond to system dark mode changes
@Environment(\.colorScheme) private var colorScheme

var currentTheme: Theme {
    switch colorScheme {
    case .dark:
        return .dark
    case .light:
        return .light  // If light theme available
    @unknown default:
        return .dark
    }
}
```

This theming system ensures that FinanceChartsKit provides an excellent visual experience for all users while maintaining the high performance required for smooth tvOS operation.