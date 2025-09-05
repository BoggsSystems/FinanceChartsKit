import Foundation
import UIKit

protocol FocusControllerDelegate: AnyObject {
    func focusController(_ controller: FocusController, didRequestQuickPalette options: [String])
    func focusController(_ controller: FocusController, didCreateAlert price: CGFloat)
}

final class FocusController {
    weak var delegate: FocusControllerDelegate?
    private weak var chartController: ChartController?
    private var panAcceleration: Int = 1
    private var panTimer: Timer?
    
    init(chartController: ChartController) {
        self.chartController = chartController
    }
    
    func handleRemoteInput(_ input: RemoteInput) {
        switch input {
        case .left:
            startPanning(direction: -1)
        case .right:
            startPanning(direction: 1)
        case .up:
            chartController?.cycleTimeframeUp()
        case .down:
            chartController?.cycleTimeframeDown()
        case .select:
            toggleCrosshair()
        case .playPause:
            toggleCrosshair()
        case .menu:
            handleMenuPress()
        case .longPress(let location):
            handleLongPress(at: location)
        case .panEnd:
            stopPanning()
        }
    }
    
    private func startPanning(direction: Int) {
        stopPanning()
        panAcceleration = 1
        
        chartController?.pan(byBars: direction * panAcceleration)
        
        panTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.panAcceleration = min(self.panAcceleration + 1, 10)
            self.chartController?.pan(byBars: direction * self.panAcceleration)
        }
    }
    
    private func stopPanning() {
        panTimer?.invalidate()
        panTimer = nil
        panAcceleration = 1
    }
    
    private func toggleCrosshair() {
        
    }
    
    private func handleMenuPress() {
        chartController?.setCrosshair(x: nil)
    }
    
    private func handleLongPress(at location: CGPoint) {
        let options = ["Add Alert", "Add RSI", "Toggle EMA 20", "Toggle EMA 50", "Toggle Bollinger"]
        delegate?.focusController(self, didRequestQuickPalette: options)
    }
}

enum RemoteInput {
    case left
    case right
    case up
    case down
    case select
    case playPause
    case menu
    case longPress(CGPoint)
    case panEnd
}