import Foundation
import QuartzCore

final class RenderScheduler {
    private var displayLink: CADisplayLink?
    private var updateCallback: (() -> Void)?
    private var lastUpdateTime: CFTimeInterval = 0
    private let targetFPS: Double = 60
    private let minFrameInterval: Double
    
    init(targetFPS: Double = 60) {
        self.targetFPS = targetFPS
        self.minFrameInterval = 1.0 / targetFPS
    }
    
    func start(updateCallback: @escaping () -> Void) {
        stop()
        
        self.updateCallback = updateCallback
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: Float(targetFPS))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        updateCallback = nil
    }
    
    @objc private func displayLinkTick(_ displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        
        if currentTime - lastUpdateTime >= minFrameInterval {
            lastUpdateTime = currentTime
            updateCallback?()
        }
    }
    
    deinit {
        stop()
    }
}