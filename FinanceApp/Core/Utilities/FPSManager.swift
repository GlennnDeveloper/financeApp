import SwiftUI
import Combine
import QuartzCore

@MainActor
class FPSManager: NSObject, ObservableObject {
    static let shared = FPSManager()
    
    @Published var currentFPS: Int = 0
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    
    override private init() {
        super.init()
    }
    
    func start() {
        stop()
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
        frameCount = 0
    }
    
    @objc private func update(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        
        frameCount += 1
        let delta = link.timestamp - lastTimestamp
        
        if delta >= 1.0 {
            currentFPS = Int(Double(frameCount) / delta)
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}
