import SwiftUI
import UIKit

public struct PriceChartView: View {
    private let controller: ChartController
    
    public init(controller: ChartController) {
        self.controller = controller
    }
    
    public var body: some View {
        ChartViewRepresentable(controller: controller)
            .onAppear {
                setupFocusHandling()
            }
    }
    
    private func setupFocusHandling() {
        
    }
}

struct ChartViewRepresentable: UIViewRepresentable {
    let controller: ChartController
    
    func makeUIView(context: Context) -> ChartView {
        let chartView = ChartView()
        chartView.attachController(controller)
        return chartView
    }
    
    func updateUIView(_ uiView: ChartView, context: Context) {
        
    }
    
    static func dismantleUIView(_ uiView: ChartView, coordinator: Coordinator) {
        uiView.detachController()
    }
}

#if os(tvOS)
extension ChartView {
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        handlePress(press, began: true)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesEnded(presses, with: event)
            return
        }
        
        handlePress(press, began: false)
    }
    
    private func handlePress(_ press: UIPress, began: Bool) {
        guard began else { return }
        
        switch press.type {
        case .leftArrow:
            controller?.pan(byBars: -5)
        case .rightArrow:
            controller?.pan(byBars: 5)
        case .upArrow:
            controller?.cycleTimeframeUp()
        case .downArrow:
            controller?.cycleTimeframeDown()
        case .select:
            toggleCrosshair()
        case .playPause:
            toggleCrosshair()
        case .menu:
            controller?.setCrosshair(x: nil)
        default:
            super.pressesBegan([press], with: nil)
        }
    }
    
    private func toggleCrosshair() {
        let centerX = bounds.width / 2
        controller?.setCrosshair(x: centerX)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        controller?.setCrosshair(x: location.x)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        controller?.setCrosshair(x: location.x)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        controller?.setCrosshair(x: nil)
    }
}
#endif