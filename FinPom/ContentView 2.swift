import SwiftUI
import UserNotifications

struct ContentView: View {
    @ObservedObject var timerModel = TimerModel.shared
    @State private var hoursInput = "00"
    @State private var minutesInput = "00"
    @State private var secondsInput = "00"
    @State private var selectedPreset: Int? = nil
    @State private var selectedWorkHours: Int = 4

    var startTimer: (Int, Int, Int) -> Void

    var body: some View {
        VStack(spacing: 6) {
            Menu {
                ForEach(4..<9) { hour in
                    Button(action: {
                        selectedPreset = hour
                        setPresetTimer(hours: hour)
                    }) {
                        Text("\(hour) hours")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("How long have you been working?")
                        .foregroundColor(.primary.opacity(0.7))
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(timerModel.state == .breakTime ? "Focus Time📚" :
                 timerModel.state == .focus ? "Break Time🏝️" : "Focus")
                .font(.system(size: 30, weight: .bold))

            HStack(spacing: 57) {
                Text("Hours")
                Text("Minutes")
                Text("Seconds")
            }
            .font(.caption)

            HStack(spacing: 8) {
                if timerModel.isRunning {
                    Text(String(format: "%02d", timerModel.hours)).font(.system(size: 40, design: .monospaced))
                    Text(":").font(.system(size: 40, design: .monospaced))
                    Text(String(format: "%02d", timerModel.minutes)).font(.system(size: 40, design: .monospaced))
                    Text(":").font(.system(size: 40, design: .monospaced))
                    Text(String(format: "%02d", timerModel.seconds)).font(.system(size: 40, design: .monospaced))
                } else {
                    timeTextField($hoursInput)
                    Text(":").font(.system(size: 40, design: .monospaced))
                    timeTextField($minutesInput)
                    Text(":").font(.system(size: 40, design: .monospaced))
                    timeTextField($secondsInput)
                }
            }

            Button {
                var h = timerModel.hours
                var m = timerModel.minutes
                var s = timerModel.seconds

                if h == 0 && m == 0 && s == 0 {
                    h = Int(hoursInput) ?? 0
                    m = Int(minutesInput) ?? 0
                    s = Int(secondsInput) ?? 0
                }

                guard h > 0 || m > 0 || s > 0 else { return }

                // 🧠 Tambahan logika rekomendasi untuk durasi 1 menit
                RecommendationScheduler.shared.triggerRecommendationIfManualInputIsOneMinute(hours: h, minutes: m, seconds: s)

                // 🔔 Logika rekomendasi untuk durasi 45 menit
                if h == 0 && m == 45 && s == 0 {
                    RecommendationScheduler.shared.scheduleDebugNotificationsFor45MinuteSession()
                }

                switch timerModel.state {
                case .start:
                    NSSound(named: "Glass")?.play()
                    startTimer(h, m, s)
                    timerModel.state = .breakTime

                    timerModel.sessionAcknowledged = true
                    let preset = SessionPreset.presetForWorkHours(selectedWorkHours)
                    RecommendationScheduler.shared.scheduleSessionNotifications(for: preset)
                    RecommendationScheduler.shared.scheduleConditionalReminders(
                        every: 300,
                        duration: TimeInterval(preset.durationInMinutes * 60),
                        sessionCheck: { !timerModel.sessionAcknowledged }
                    )

                case .breakTime:
                    NSSound(named: "Funk")?.play()
                    startTimer(h, m, s)
                    timerModel.state = .focus

                case .focus:
                    NSSound(named: "Hero")?.play()
                    startTimer(h, m, s)
                    timerModel.state = .breakTime
                }
            } label: {
                Text(buttonLabel)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 42)
                    .background(Color.blue)
                    .cornerRadius(12)
            }

            // 🔧 Tombol tambahan untuk mini-sesi 1 menit (debug/test)
            Button {
                timerModel.hours = 0
                timerModel.minutes = 1
                timerModel.seconds = 0
                timerModel.sessionAcknowledged = true
                startTimer(0, 1, 0)
                

            } label: {
                Text("Tes Mini Sesi")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(width: 330, height: 240)
    }

    func timeTextField(_ binding: Binding<String>) -> some View {
        TextField("00", text: binding)
            .frame(width: 50)
            .textFieldStyle(.plain)
            .font(.system(size: 45, design: .monospaced))
            .multilineTextAlignment(.center)
    }

    func setPresetTimer(hours: Int) {
        hoursInput = String(format: "%02d", hours)
        minutesInput = "00"
        secondsInput = "00"

        let h = Int(hoursInput) ?? 0
        let m = Int(minutesInput) ?? 0
        let s = Int(secondsInput) ?? 0
        startTimer(h, m, s)
    }

    var buttonLabel: String {
        switch timerModel.state {
        case .start: return "Start"
        case .breakTime: return "Break"
        case .focus: return "Focus"
        }
    }
}

#Preview {
    ContentView(startTimer: { _,_,_ in })
}
