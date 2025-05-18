//
//  SessionPreset.swift
//  TimerMenuBarApp
//
//  Created by grace maria yosephine agustin gultom on 17/05/25.
//


import Foundation
import UserNotifications

struct SessionPreset {
    let durationInMinutes: Int
    let sessions: Int
    let focusMinutesPerSession: Int = 25

    var breakMinutesPerSession: Double {
        Double(durationInMinutes - (focusMinutesPerSession * sessions)) / Double(sessions)
    }

    var totalFocus: Int {
        focusMinutesPerSession * sessions
    }

    var totalBreak: Int {
        durationInMinutes - totalFocus
    }

    static func presetForWorkHours(_ hours: Int) -> SessionPreset {
        switch hours {
        case 4: return SessionPreset(durationInMinutes: 240, sessions: 8)
        case 5: return SessionPreset(durationInMinutes: 300, sessions: 10)
        case 6: return SessionPreset(durationInMinutes: 360, sessions: 12)
        case 7: return SessionPreset(durationInMinutes: 420, sessions: 14)
        case 8: return SessionPreset(durationInMinutes: 480, sessions: 16)
        default: return SessionPreset(durationInMinutes: hours * 60, sessions: (hours * 60) / 30)
        }
    }
}

class RecommendationScheduler {
    static let shared = RecommendationScheduler()

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("🔐 Notification granted: \(granted)")
            }
        }
    }

    func triggerRecommendationIfManualInputIsOneMinute(hours: Int, minutes: Int, seconds: Int) {
        let total = (hours * 3600) + (minutes * 60) + seconds
        if total == 60 {
            scheduleNotification(
                title: "1 Minute Focus",
                body: "You’ve entered a 1-minute session. Make the most of it!",
                after: 60
            )
        }
    }

    func scheduleSessionNotifications(for preset: SessionPreset) {
        let focus = preset.focusMinutesPerSession
        let breakTime = preset.breakMinutesPerSession

        for i in 0..<preset.sessions {
            let sessionStart = TimeInterval(i) * TimeInterval(focus + Int(breakTime)) * 60
            let formattedBreak = String(format: "%.1f", breakTime)

            scheduleNotification(
                title: "Focus Session \(i + 1)",
                body: "Start your focus session now!",
                after: sessionStart
            )

            scheduleNotification(
                title: "Break Time",
                body: "Take a \(formattedBreak)-minute break!",
                after: sessionStart + TimeInterval(focus * 60)
            )
        }

        let totalTime = TimeInterval(preset.durationInMinutes * 60)
        scheduleNotification(
            title: "All Sessions Complete 🎉",
            body: "You've completed all your sessions. Great job!",
            after: totalTime
        )
    }

    func scheduleDebugNotificationsFor45MinuteSession() {
        scheduleNotification(
            title: "Let’s Focus 📚",
            body: "Time to focus. One task at a time!",
            after: 2700 // 45 minutes
        )
        scheduleNotification(
            title: "Let’s Break 💆🏼‍♀️",
            body: "Enjoy your break, now it’s time to recharge!",
            after: 2730 // 45 min + 30 sec
        )
        scheduleNotification(
            title: "YOU DID IT 🎊",
            body: "Great work! You've completed your 45-minute focus session!",
            after: 2760 // 46 minutes
        )
    }

    
    func scheduleConditionalReminders(
        every interval: TimeInterval,
        duration: TimeInterval,
        sessionCheck: @escaping () -> Bool
    ) {
        let repeats = Int(duration / interval)
        for i in 0..<repeats {
            let delay = TimeInterval(i + 1) * interval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if sessionCheck() {
                    self.scheduleNotification(
                        title: "Ingat Waktunya",
                        body: "Kamu belum memulai sesi. Ayo mulai sekarang untuk tetap produktif!",
                        after: 1
                    )
                }
            }
        }
    }

private func scheduleNotification(title: String, body: String, after delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled: \(title) in \(delay) sec")
            }
        }
    }
}
