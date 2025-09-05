import XCTest
@testable import FinanceChartsKit

#if os(tvOS)
final class ChartInteractionTests: XCTestCase {
    var chartController: ChartController!
    var chartView: ChartView!
    
    override func setUp() {
        super.setUp()
        chartController = ChartController()
        chartView = ChartView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        chartView.attachController(chartController)
        
        let testCandles = generateTestCandles()
        chartController.setData(testCandles)
    }
    
    override func tearDown() {
        chartView.detachController()
        chartView = nil
        chartController = nil
        super.tearDown()
    }
    
    func testFocusBehavior() {
        XCTAssertTrue(chartView.canBecomeFocused, "Chart view should be focusable")
        
        let focusSuccess = chartView.becomeFirstResponder()
        XCTAssertTrue(focusSuccess, "Chart view should be able to become first responder")
    }
    
    func testRemoteNavigationLeft() {
        let initialPanOffset = getPrivatePanOffset()
        
        simulateRemotePress(.leftArrow)
        
        let newPanOffset = getPrivatePanOffset()
        XCTAssertNotEqual(initialPanOffset, newPanOffset, "Pan offset should change on left arrow")
    }
    
    func testRemoteNavigationRight() {
        chartController.pan(byBars: -10)
        let initialPanOffset = getPrivatePanOffset()
        
        simulateRemotePress(.rightArrow)
        
        let newPanOffset = getPrivatePanOffset()
        XCTAssertNotEqual(initialPanOffset, newPanOffset, "Pan offset should change on right arrow")
    }
    
    func testTimeframeCycling() {
        let initialTimeframe = chartController.timeframe
        
        simulateRemotePress(.upArrow)
        
        XCTAssertNotEqual(initialTimeframe, chartController.timeframe, "Timeframe should change on up arrow")
    }
    
    func testCrosshairToggle() {
        simulateRemotePress(.select)
        
        
    }
    
    func testMenuPress() {
        chartController.setCrosshair(x: 100)
        
        simulateRemotePress(.menu)
        
        
    }
    
    func testTouchInteraction() {
        let touchLocation = CGPoint(x: 100, y: 100)
        
        let touch = MockTouch(location: touchLocation, view: chartView)
        chartView.touchesBegan(Set([touch]), with: nil)
        
        
        chartView.touchesEnded(Set([touch]), with: nil)
    }
    
    func testPerformanceUnderInteraction() {
        measure {
            for _ in 0..<100 {
                simulateRemotePress(.rightArrow)
                simulateRemotePress(.leftArrow)
            }
        }
    }
    
    private func simulateRemotePress(_ type: UIPress.PressType) {
        let press = MockPress(type: type)
        chartView.pressesBegan(Set([press]), with: nil)
        chartView.pressesEnded(Set([press]), with: nil)
    }
    
    private func getPrivatePanOffset() -> Int {
        
        return 0
    }
    
    private func generateTestCandles() -> [Candle] {
        return (0..<100).map { i in
            Candle(
                timestamp: TimeInterval(i * 3600),
                open: 100 + CGFloat(i % 10),
                high: 105 + CGFloat(i % 10),
                low: 95 + CGFloat(i % 10),
                close: 102 + CGFloat(i % 10),
                volume: 50000
            )
        }
    }
}

private class MockPress: UIPress {
    private let _type: PressType
    
    init(type: PressType) {
        _type = type
        super.init()
    }
    
    override var type: PressType {
        return _type
    }
}

private class MockTouch: UITouch {
    private let _location: CGPoint
    private let _view: UIView
    
    init(location: CGPoint, view: UIView) {
        _location = location
        _view = view
        super.init()
    }
    
    override func location(in view: UIView?) -> CGPoint {
        return _location
    }
}

#endif