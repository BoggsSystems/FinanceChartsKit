import SwiftUI
import FinanceChartsKit

struct ContentView: View {
    @StateObject private var chartController = ChartController()
    @State private var showSideTray = false
    @State private var isSimulatingTicks = false
    @State private var tickTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                HStack(spacing: 0) {
                    chartArea
                        .frame(width: showSideTray ? geometry.size.width * 0.7 : geometry.size.width)
                    
                    if showSideTray {
                        sideTray
                            .frame(width: geometry.size.width * 0.3)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .onAppear {
            setupChartData()
        }
        .onDisappear {
            stopTickSimulation()
        }
        .focusable()
        .onMoveCommand { direction in
            handleRemoteNavigation(direction)
        }
        .onPlayPauseCommand {
            handlePlayPause()
        }
        .onExitCommand {
            showSideTray = false
        }
    }
    
    private var chartArea: some View {
        PriceChartView(controller: chartController)
            .background(Color.black)
            .onTapGesture {
                showSideTray.toggle()
            }
    }
    
    private var sideTray: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Trading Controls")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            Group {
                Button("Toggle RSI") {
                    chartController.toggleIndicator(.rsi14)
                }
                
                Button("Toggle EMA 20") {
                    chartController.toggleOverlay(.ema20)
                }
                
                Button("Toggle EMA 50") {
                    chartController.toggleOverlay(.ema50)
                }
                
                Button("Toggle Bollinger") {
                    chartController.toggleOverlay(.bollinger20)
                }
            }
            .buttonStyle(TrayButtonStyle())
            
            Divider()
                .background(Color.gray)
            
            Group {
                Button("1 Minute") {
                    chartController.timeframe = .m1
                }
                
                Button("5 Minutes") {
                    chartController.timeframe = .m5
                }
                
                Button("15 Minutes") {
                    chartController.timeframe = .m15
                }
                
                Button("1 Hour") {
                    chartController.timeframe = .h1
                }
                
                Button("1 Day") {
                    chartController.timeframe = .d1
                }
            }
            .buttonStyle(TrayButtonStyle())
            
            Divider()
                .background(Color.gray)
            
            Button(isSimulatingTicks ? "Stop Simulation" : "Start Simulation") {
                if isSimulatingTicks {
                    stopTickSimulation()
                } else {
                    startTickSimulation()
                }
            }
            .buttonStyle(TrayButtonStyle())
            
            Button("Export Snapshot") {
                if let snapshot = chartController.snapshot() {
                    
                }
            }
            .buttonStyle(TrayButtonStyle())
            
            Spacer()
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .animation(.easeInOut(duration: 0.3), value: showSideTray)
    }
    
    private func setupChartData() {
        chartController.symbol = "TSLA"
        chartController.setData(TeslaDataProvider.teslaOHLCData)
        chartController.setTheme(.dark)
    }
    
    private func handleRemoteNavigation(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            chartController.pan(byBars: -5)
        case .right:
            chartController.pan(byBars: 5)
        case .up:
            chartController.cycleTimeframeUp()
        case .down:
            chartController.cycleTimeframeDown()
        @unknown default:
            break
        }
    }
    
    private func handlePlayPause() {
        let centerX = UIScreen.main.bounds.width / 2
        chartController.setCrosshair(x: centerX)
    }
    
    private func startTickSimulation() {
        isSimulatingTicks = true
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            simulateRandomTick()
        }
    }
    
    private func stopTickSimulation() {
        isSimulatingTicks = false
        tickTimer?.invalidate()
        tickTimer = nil
    }
    
    private func simulateRandomTick() {
        let randomChange = CGFloat.random(in: -2.0...2.0)
        let currentPrice = TeslaDataProvider.teslaOHLCData.last?.close ?? 250.0
        let newPrice = max(1.0, currentPrice + randomChange)
        
        let updatedCandle = Candle(
            timestamp: Date().timeIntervalSince1970,
            open: currentPrice,
            high: max(currentPrice, newPrice),
            low: min(currentPrice, newPrice),
            close: newPrice,
            volume: CGFloat.random(in: 1000...10000)
        )
        
        chartController.updateLast(updatedCandle)
    }
}

struct TrayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(configuration.isPressed ? 0.5 : 0.3))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}