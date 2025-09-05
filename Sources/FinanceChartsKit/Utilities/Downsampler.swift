import Foundation
import CoreGraphics

public final class Downsampler {
    
    public static func lttb(data: [Candle], targetPoints: Int) -> [Candle] {
        guard targetPoints > 0 && data.count > targetPoints else { return data }
        guard targetPoints >= 3 else { return Array(data.prefix(targetPoints)) }
        
        let bucketSize = Double(data.count - 2) / Double(targetPoints - 2)
        var sampled: [Candle] = []
        
        sampled.append(data.first!)
        
        var bucketIndex = 0.0
        for i in 0..<(targetPoints - 2) {
            let currentBucketStart = Int(floor(bucketIndex)) + 1
            bucketIndex += bucketSize
            let currentBucketEnd = min(Int(floor(bucketIndex)) + 1, data.count - 1)
            
            let nextBucketStart = currentBucketEnd
            let nextBucketEnd = min(Int(floor(bucketIndex + bucketSize)) + 1, data.count - 1)
            
            var maxArea: Double = -1
            var maxAreaIndex = currentBucketStart
            
            let nextAverage = averagePoint(data: data, start: nextBucketStart, end: nextBucketEnd)
            let prevPoint = pointFromCandle(sampled.last!)
            
            for j in currentBucketStart..<currentBucketEnd {
                let currentPoint = pointFromCandle(data[j])
                let area = triangleArea(a: prevPoint, b: currentPoint, c: nextAverage)
                
                if area > maxArea {
                    maxArea = area
                    maxAreaIndex = j
                }
            }
            
            sampled.append(data[maxAreaIndex])
        }
        
        sampled.append(data.last!)
        return sampled
    }
    
    public static func minMaxDownsample(data: [Candle], targetPixelWidth: Int) -> [Candle] {
        guard targetPixelWidth > 0 && data.count > targetPixelWidth * 2 else { return data }
        
        let pointsPerPixel = data.count / targetPixelWidth
        var sampled: [Candle] = []
        
        for i in stride(from: 0, to: data.count, by: pointsPerPixel) {
            let endIndex = min(i + pointsPerPixel, data.count)
            let slice = Array(data[i..<endIndex])
            
            if let minCandle = slice.min(by: { $0.low < $1.low }),
               let maxCandle = slice.max(by: { $0.high < $1.high }) {
                
                if minCandle.timestamp <= maxCandle.timestamp {
                    if minCandle != maxCandle {
                        sampled.append(minCandle)
                    }
                    sampled.append(maxCandle)
                } else {
                    if maxCandle != minCandle {
                        sampled.append(maxCandle)
                    }
                    sampled.append(minCandle)
                }
            }
        }
        
        return sampled
    }
    
    private static func pointFromCandle(_ candle: Candle) -> CGPoint {
        return CGPoint(x: candle.timestamp, y: Double(candle.close))
    }
    
    private static func averagePoint(data: [Candle], start: Int, end: Int) -> CGPoint {
        guard start < end && start >= 0 && end <= data.count else {
            return CGPoint.zero
        }
        
        var sumX: Double = 0
        var sumY: Double = 0
        let count = end - start
        
        for i in start..<end {
            sumX += data[i].timestamp
            sumY += Double(data[i].close)
        }
        
        return CGPoint(x: sumX / Double(count), y: sumY / Double(count))
    }
    
    private static func triangleArea(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        return abs((a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2.0)
    }
}