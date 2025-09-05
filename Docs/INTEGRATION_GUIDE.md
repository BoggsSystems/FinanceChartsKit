# Integration Guide

## Overview

This guide covers how to integrate FinanceChartsKit with live data sources, particularly WebSocket feeds, and how to implement real-time tick aggregation to OHLC candle data.

## WebSocket Integration

### Basic WebSocket Setup

```swift
import Foundation
import Starscream
import FinanceChartsKit

class WebSocketDataProvider: ObservableObject {
    private var socket: WebSocket?
    private let chartController: ChartController
    private var ohlcBuilders: [String: OHLCBuilder] = [:]
    
    init(chartController: ChartController) {
        self.chartController = chartController
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        var request = URLRequest(url: URL(string: "wss://api.example.com/ws")!)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
}

extension WebSocketDataProvider: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("WebSocket connected: \(headers)")
            subscribeToSymbol(chartController.symbol)
            chartController.setConnectionStatus(true)
            
        case .disconnected(let reason, let code):
            print("WebSocket disconnected: \(reason) with code: \(code)")
            chartController.setConnectionStatus(false)
            reconnectAfterDelay()
            
        case .text(let string):
            handleMessage(string)
            
        case .binary(let data):
            handleBinaryMessage(data)
            
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown")")
            chartController.setConnectionStatus(false)
            
        default:
            break
        }
    }
}
```

### Message Handling

```swift
extension WebSocketDataProvider {
    private func handleMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        switch json["type"] as? String {
        case "tick":
            handleTick(json)
        case "candle":
            handleCandle(json)
        case "snapshot":
            handleSnapshot(json)
        default:
            print("Unknown message type: \(json)")
        }
    }
    
    private func handleTick(_ json: [String: Any]) {
        guard let symbol = json["symbol"] as? String,
              let timestamp = json["timestamp"] as? TimeInterval,
              let price = json["price"] as? Double,
              let volume = json["volume"] as? Double else {
            return
        }
        
        // Only process ticks for current symbol
        guard symbol == chartController.symbol else { return }
        
        let tick = Tick(
            timestamp: timestamp,
            price: CGFloat(price),
            volume: CGFloat(volume)
        )
        
        processLiveTick(tick, for: symbol)
    }
    
    private func handleCandle(_ json: [String: Any]) {
        guard let symbol = json["symbol"] as? String,
              let timestamp = json["timestamp"] as? TimeInterval,
              let open = json["open"] as? Double,
              let high = json["high"] as? Double,
              let low = json["low"] as? Double,
              let close = json["close"] as? Double,
              let volume = json["volume"] as? Double else {
            return
        }
        
        guard symbol == chartController.symbol else { return }
        
        let candle = Candle(
            timestamp: timestamp,
            open: CGFloat(open),
            high: CGFloat(high),
            low: CGFloat(low),
            close: CGFloat(close),
            volume: CGFloat(volume)
        )
        
        DispatchQueue.main.async {
            self.chartController.append(candle)
        }
    }
}
```

### Tick Aggregation

```swift
extension WebSocketDataProvider {
    private func processLiveTick(_ tick: Tick, for symbol: String) {
        // Get or create OHLC builder for this symbol/timeframe combination
        let builderKey = "\(symbol)_\(chartController.timeframe.rawValue)"
        
        if ohlcBuilders[builderKey] == nil {
            ohlcBuilders[builderKey] = OHLCBuilder(timeframe: chartController.timeframe)
        }
        
        guard let builder = ohlcBuilders[builderKey] else { return }
        
        let result = builder.ingest(tick)
        
        DispatchQueue.main.async {
            // Update the current candle in real-time
            if let updated = result.updated {
                self.chartController.updateLast(updated)
            }
            
            // Append new completed candle
            if let appended = result.appended {
                self.chartController.append(appended)
            }
        }
    }
    
    func changeTimeframe(_ newTimeframe: Timeframe) {
        // Clear existing builders when timeframe changes
        ohlcBuilders.removeAll()
        
        // Request historical data for new timeframe
        requestHistoricalData(symbol: chartController.symbol, timeframe: newTimeframe)
    }
}
```

### Connection Management

```swift
extension WebSocketDataProvider {
    private func reconnectAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard self.socket?.isConnected != true else { return }
            
            self.socket?.connect()
        }
    }
    
    func subscribeToSymbol(_ symbol: String) {
        let subscription = [
            "action": "subscribe",
            "symbol": symbol,
            "timeframe": chartController.timeframe.rawValue
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: subscription),
           let message = String(data: data, encoding: .utf8) {
            socket?.write(string: message)
        }
    }
    
    func unsubscribeFromSymbol(_ symbol: String) {
        let unsubscription = [
            "action": "unsubscribe", 
            "symbol": symbol
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: unsubscription),
           let message = String(data: data, encoding: .utf8) {
            socket?.write(string: message)
        }
    }
}
```

## REST API Integration

### Historical Data Loading

```swift
class APIDataProvider {
    private let chartController: ChartController
    private let baseURL = "https://api.example.com/v1"
    
    init(chartController: ChartController) {
        self.chartController = chartController
    }
    
    func loadHistoricalData(symbol: String, timeframe: Timeframe, limit: Int = 1000) async {
        let endpoint = "\(baseURL)/candles"
        var components = URLComponents(string: endpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "timeframe", value: timeframe.rawValue),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components?.url else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let candleData = try JSONDecoder().decode([CandleResponse].self, from: data)
            
            let candles = candleData.map { response in
                Candle(
                    timestamp: response.timestamp,
                    open: CGFloat(response.open),
                    high: CGFloat(response.high),
                    low: CGFloat(response.low),
                    close: CGFloat(response.close),
                    volume: CGFloat(response.volume)
                )
            }
            
            await MainActor.run {
                self.chartController.setData(candles)
            }
            
        } catch {
            print("Failed to load historical data: \(error)")
        }
    }
}

struct CandleResponse: Codable {
    let timestamp: TimeInterval
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}
```

### Rate Limiting

```swift
class RateLimitedAPIProvider {
    private let requestQueue = DispatchQueue(label: "api-requests", qos: .utility)
    private var lastRequestTime: Date = Date.distantPast
    private let minRequestInterval: TimeInterval = 1.0 // 1 request per second
    
    func makeRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async {
                let now = Date()
                let timeSinceLastRequest = now.timeIntervalSince(self.lastRequestTime)
                
                if timeSinceLastRequest < self.minRequestInterval {
                    let delay = self.minRequestInterval - timeSinceLastRequest
                    Thread.sleep(forTimeInterval: delay)
                }
                
                self.lastRequestTime = Date()
                
                // Make actual request
                Task {
                    do {
                        let result = try await self.performRequest(endpoint: endpoint, responseType: responseType)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func performRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(responseType, from: data)
    }
}

enum APIError: Error {
    case invalidURL
    case rateLimitExceeded
    case invalidResponse
}
```

## Data Validation & Error Handling

### Tick Validation

```swift
extension WebSocketDataProvider {
    private func validateTick(_ tick: Tick) -> Bool {
        // Basic validation rules
        guard tick.price > 0 else {
            print("Invalid tick: negative or zero price")
            return false
        }
        
        guard tick.volume >= 0 else {
            print("Invalid tick: negative volume")
            return false
        }
        
        guard tick.timestamp > 0 else {
            print("Invalid tick: invalid timestamp")
            return false
        }
        
        // Check for reasonable price ranges (optional)
        let currentTime = Date().timeIntervalSince1970
        let maxAge: TimeInterval = 300 // 5 minutes
        
        guard currentTime - tick.timestamp < maxAge else {
            print("Invalid tick: timestamp too old")
            return false
        }
        
        return true
    }
    
    private func processLiveTick(_ tick: Tick, for symbol: String) {
        guard validateTick(tick) else { return }
        
        // Continue with normal processing...
        let builderKey = "\(symbol)_\(chartController.timeframe.rawValue)"
        // ... rest of implementation
    }
}
```

### Connection Recovery

```swift
extension WebSocketDataProvider {
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    
    private func reconnectWithBackoff() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("Max reconnection attempts reached")
            return
        }
        
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            print("Reconnection attempt \(self.reconnectAttempts)")
            self.socket?.connect()
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            reconnectAttempts = 0 // Reset on successful connection
            chartController.setConnectionStatus(true)
            
        case .disconnected(let reason, let code):
            chartController.setConnectionStatus(false)
            
            // Don't reconnect if disconnection was intentional
            guard code != CloseCode.normal.rawValue else { return }
            
            reconnectWithBackoff()
            
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown")")
            chartController.setConnectionStatus(false)
            reconnectWithBackoff()
            
        default:
            break
        }
    }
}
```

## Multi-Symbol Support

### Symbol Management

```swift
class MultiSymbolDataProvider: ObservableObject {
    private var webSocketProviders: [String: WebSocketDataProvider] = [:]
    private var chartControllers: [String: ChartController] = [:]
    
    func addSymbol(_ symbol: String) -> ChartController {
        if let existing = chartControllers[symbol] {
            return existing
        }
        
        let controller = ChartController()
        controller.symbol = symbol
        
        let provider = WebSocketDataProvider(chartController: controller)
        
        chartControllers[symbol] = controller
        webSocketProviders[symbol] = provider
        
        return controller
    }
    
    func removeSymbol(_ symbol: String) {
        webSocketProviders[symbol]?.disconnect()
        webSocketProviders.removeValue(forKey: symbol)
        chartControllers.removeValue(forKey: symbol)
    }
    
    func getController(for symbol: String) -> ChartController? {
        return chartControllers[symbol]
    }
}
```

### Resource Management

```swift
extension MultiSymbolDataProvider {
    func pauseInactiveSymbols() {
        for (symbol, provider) in webSocketProviders {
            // Pause symbols that aren't currently being viewed
            if !isSymbolActive(symbol) {
                provider.pauseUpdates()
            }
        }
    }
    
    func resumeSymbol(_ symbol: String) {
        webSocketProviders[symbol]?.resumeUpdates()
    }
    
    private func isSymbolActive(_ symbol: String) -> Bool {
        // Implement logic to determine if symbol is currently visible
        // This could be based on which chart is in the foreground,
        // or which symbols are in visible tabs, etc.
        return true // Placeholder
    }
}
```

## Performance Considerations

### Throttling Updates

```swift
class ThrottledUpdateManager {
    private var pendingUpdate: Candle?
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 1.0 / 30.0 // 30 FPS max
    private let chartController: ChartController
    
    init(chartController: ChartController) {
        self.chartController = chartController
    }
    
    func queueUpdate(_ candle: Candle) {
        pendingUpdate = candle
        
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: false) { _ in
                self.flushUpdate()
            }
        }
    }
    
    private func flushUpdate() {
        defer {
            pendingUpdate = nil
            updateTimer = nil
        }
        
        guard let candle = pendingUpdate else { return }
        
        DispatchQueue.main.async {
            self.chartController.updateLast(candle)
        }
    }
}
```

### Memory Management

```swift
extension WebSocketDataProvider {
    private func manageMemory() {
        // Limit stored historical data
        let maxStoredCandles = 10000
        
        if chartController.totalCandleCount > maxStoredCandles {
            chartController.trimOldData(keepingLast: maxStoredCandles)
        }
        
        // Clear old OHLC builders
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago
        
        ohlcBuilders = ohlcBuilders.filter { key, builder in
            builder.lastUpdateTime > cutoffTime.timeIntervalSince1970
        }
    }
}
```

## Testing Integration

### Mock Data Provider

```swift
class MockDataProvider: ObservableObject {
    private let chartController: ChartController
    private var simulationTimer: Timer?
    
    init(chartController: ChartController) {
        self.chartController = chartController
    }
    
    func startSimulation() {
        // Load initial data
        chartController.setData(generateHistoricalData())
        
        // Start live simulation
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.simulateNextTick()
        }
    }
    
    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    private func simulateNextTick() {
        let randomChange = CGFloat.random(in: -2.0...2.0)
        let currentPrice = chartController.lastPrice
        let newPrice = max(1.0, currentPrice + randomChange)
        
        let tick = Tick(
            timestamp: Date().timeIntervalSince1970,
            price: newPrice,
            volume: CGFloat.random(in: 100...1000)
        )
        
        // Process through OHLC builder just like real data
        let builder = OHLCBuilder(timeframe: chartController.timeframe)
        let result = builder.ingest(tick)
        
        if let updated = result.updated {
            chartController.updateLast(updated)
        }
        
        if let appended = result.appended {
            chartController.append(appended)
        }
    }
}
```

This integration guide provides a comprehensive foundation for connecting FinanceChartsKit to live data sources, handling real-time updates, and managing the complexities of financial data streaming in a production environment.