import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timer: Timer?
    let timerModel = TimerModel.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        RecommendationScheduler.shared.requestNotificationPermission()

        let contentView = ContentView(startTimer: startTimer)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 220)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Focus Timer")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.close()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func startTimer(hours: Int, minutes: Int, seconds: Int) {
        var totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        guard totalSeconds > 0 else { return }

        timerModel.isRunning = true
        timerModel.update(from: totalSeconds)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            totalSeconds -= 1
            if totalSeconds <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                self.timerModel.reset()
                self.statusItem.button?.title = ""
                self.showNotification()
            } else {
                self.timerModel.update(from: totalSeconds)
                self.statusItem.button?.title = String(format: "%d:%02d:%02d", self.timerModel.hours, self.timerModel.minutes, self.timerModel.seconds)
            }
        }

        popover.close()
    }

    func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "YOU DID IT🎉"
        content.body = "TENGGO, TENGGO, TENGGO."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func scheduleDebugNotificationsFor1MinuteSession() {
        scheduleCustomNotification(title: "Lets Focus 📚", body: "Time to Focus. One task at a time", after: 45)
        scheduleCustomNotification(title: "Lets Break 💆🏼‍♀️", body: "Enjoy your Break, Now it's time to recharge!", after: 15)
        scheduleCustomNotification(title: "YOU DID IT 🎊", body: "TENGGO, TENGGO, TENGGO", after: 60)
    }

    private func scheduleCustomNotification(title: String, body: String, after delay: TimeInterval) {
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
                print("✅ Notifikasi dijadwalkan: \(title) – Delay: \(delay) detik")
            }
        }
    }
}
