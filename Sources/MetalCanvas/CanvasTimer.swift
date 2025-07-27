import Foundation
import QuartzCore

class CanvasTimer {
    private var startTime: TimeInterval
    private var pausedTime: TimeInterval = 0
    private var pauseStartTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    
    private(set) var current: TimeInterval = 0
    private(set) var delta: TimeInterval = 0
    private(set) var isPaused: Bool = false
    
    init() {
        startTime = CACurrentMediaTime()
        lastUpdateTime = startTime
    }
    
    func update() {
        guard !isPaused else { return }
        
        let now = CACurrentMediaTime()
        delta = now - lastUpdateTime
        lastUpdateTime = now
        current = now - startTime - pausedTime
    }
    
    func pause() {
        guard !isPaused else { return }
        isPaused = true
        pauseStartTime = CACurrentMediaTime()
    }
    
    func play() {
        guard isPaused else { return }
        isPaused = false
        let now = CACurrentMediaTime()
        pausedTime += now - pauseStartTime
        lastUpdateTime = now
    }
    
    func toggle() {
        if isPaused {
            play()
        } else {
            pause()
        }
    }
    
    func reset() {
        startTime = CACurrentMediaTime()
        lastUpdateTime = startTime
        pausedTime = 0
        pauseStartTime = 0
        current = 0
        delta = 0
        isPaused = false
    }
}