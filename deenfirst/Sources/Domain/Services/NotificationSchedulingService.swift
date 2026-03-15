import Foundation
import UserNotifications

protocol NotificationSchedulingService {
    func scheduleTimeLimitWarning(for rule: ScreenTimeRule)
    func cancelTimeLimitWarning(for ruleId: UUID)
    func scheduleMotivationalNotifications() async
    func cancelMotivationalNotifications() async
}

final class NotificationSchedulingServiceImpl: NotificationSchedulingService {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    private let dayNameToWeekday: [String: Int] = [
        "Sunday": 1,
        "Monday": 2,
        "Tuesday": 3,
        "Wednesday": 4,
        "Thursday": 5,
        "Friday": 6,
        "Saturday": 7,
    ]

    private let morningMessages = [
        "Good morning 🌙 Start a focus session and get closer to Allah",
        "A new day, a new chance to build your deen. Begin a session now 📿",
        "Before the distractions begin — dedicate this moment to your deen",
        "The early hours are blessed. Make them count with a focus session 🤲",
        "Remember why you started this journey. Start your session now 🕌",
    ]

    private let eveningMessages = [
        "The day isn't over yet 🌅 Remember why you started this journey",
        "End your evening closer to Allah. Start a focus session 📿",
        "Don't let the day close without remembering Allah. Begin a session 🤲",
        "A few focused minutes now can transform your heart. Start a session",
        "Your deen deserves your best — even in the evening 🕌",
    ]

    func scheduleTimeLimitWarning(for rule: ScreenTimeRule) {
        guard let startTime = rule.getStartTimeComponents() else { return }

        let startHour = startTime.hour ?? 0
        let startMinute = startTime.minute ?? 0
        let startTotalMinutes = (startHour * 60) + startMinute
        let rawWarningMinutes = startTotalMinutes - 10
        let warningTotalMinutes = (rawWarningMinutes + 1440) % 1440
        let needsPreviousDay = rawWarningMinutes < 0

        var warningComponents = DateComponents()
        warningComponents.hour = warningTotalMinutes / 60
        warningComponents.minute = warningTotalMinutes % 60

        cancelTimeLimitWarning(for: rule.id)

        let weekdays = activeWeekdays(for: rule)
        guard !weekdays.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Deen First"
        content.body = "\"\(rule.name)\" will be blocked in 10 minutes"
        content.sound = .default

        for weekday in weekdays {
            let triggerWeekday = needsPreviousDay ? previousWeekday(from: weekday) : weekday
            warningComponents.weekday = triggerWeekday

            let trigger = UNCalendarNotificationTrigger(dateMatching: warningComponents, repeats: true)
            let identifier = AppGroupConstants.timeLimitWarningNotificationId(
                for: rule.id,
                weekday: weekday
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error {
                    print("⚠️ [NotificationScheduling] Failed time-limit warning for \(rule.id), day \(weekday): \(error)")
                } else {
                    print("✅ [NotificationScheduling] Time-limit warning scheduled for \(rule.id), day \(weekday)")
                }
            }
        }
    }

    func cancelTimeLimitWarning(for ruleId: UUID) {
        var identifiers = [AppGroupConstants.timeLimitWarningNotificationId(for: ruleId)]
        identifiers += (1...7).map { weekday in
            AppGroupConstants.timeLimitWarningNotificationId(for: ruleId, weekday: weekday)
        }

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }

    func scheduleMotivationalNotifications() async {
        await cancelMotivationalNotifications()

        for dayOffset in 0..<14 {
            scheduleMotivationalNotification(dayOffset: dayOffset, period: "morning")
            scheduleMotivationalNotification(dayOffset: dayOffset, period: "evening")
        }
    }

    func cancelMotivationalNotifications() async {
        let pendingRequests = await getPendingRequests()
        let motivationalIdentifiers = pendingRequests.filter {
            $0.identifier.hasPrefix(AppGroupConstants.motivationalNotificationPrefix)
        }.map(\.identifier)

        if !motivationalIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: motivationalIdentifiers)
        }
    }

    private func getPendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private func scheduleMotivationalNotification(dayOffset: Int, period: String) {
        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { return }

        let hourRange: ClosedRange<Int> = period == "morning" ? 7...11 : 17...20
        let randomHour = Int.random(in: hourRange)
        let randomMinute = Int.random(in: 0...59)

        guard
            let scheduledDate = calendar.date(
                bySettingHour: randomHour,
                minute: randomMinute,
                second: 0,
                of: date
            ),
            scheduledDate > Date()
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Deen First"
        content.body = randomMessage(for: period)
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier =
            "\(AppGroupConstants.motivationalNotificationPrefix)\(dayOffset)_\(period)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error {
                print("⚠️ [NotificationScheduling] Failed motivational \(identifier): \(error)")
            } else {
                print("✅ [NotificationScheduling] Motivational scheduled: \(identifier)")
            }
        }
    }

    private func randomMessage(for period: String) -> String {
        let pool = period == "morning" ? morningMessages : eveningMessages
        return pool.randomElement() ?? "Start a focus session now."
    }

    private func activeWeekdays(for rule: ScreenTimeRule) -> [Int] {
        guard let daysActive = rule.daysActive, !daysActive.isEmpty else {
            return Array(1...7)
        }

        return daysActive.compactMap { dayNameToWeekday[$0] }.sorted()
    }

    private func previousWeekday(from weekday: Int) -> Int {
        weekday == 1 ? 7 : weekday - 1
    }
}
