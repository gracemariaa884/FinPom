import Foundation
import Combine

class TimerModel: ObservableObject {
    static let shared = TimerModel()

    enum TimerState {
        case start
        case breakTime
        case focus
    }

    @Published var hours: Int = 0
    @Published var minutes: Int = 0
    @Published var seconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var state: TimerState = .start
    @Published var sessionAcknowledged: Bool = false


    func update(from totalSeconds: Int) {
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
    }

    func reset() {
        hours = 0
        minutes = 0
        seconds = 0
        isRunning = false
        state = .start
    }
}
