import SwiftUI

enum Kind: String, Codable { case buy, eat }
struct Entry: Codable, Identifiable { var id = UUID(); var date: Date; var kind: Kind; var bunches: Int }
struct Badge: Identifiable { let id: String; let emoji: String; let title: String; let detail: String; let unlocked: Bool }

final class Store: ObservableObject {
    @Published var entries: [Entry] = [] { didSet { save() } }
    @Published var target = 1 { didSet { UserDefaults.standard.set(target, forKey: "target") } }
    private let cal = Calendar.current
    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("AakuQuest")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("entries.json")
        if let d = try? Data(contentsOf: url), let e = try? JSONDecoder().decode([Entry].self, from: d) { entries = e }
        let t = UserDefaults.standard.integer(forKey: "target"); target = t == 0 ? 1 : t
    }
    private func save() { try? JSONEncoder().encode(entries).write(to: url) }
    func add(_ k: Kind, _ n: Int = 1) { entries.append(Entry(date: Date(), kind: k, bunches: n)) }

    // MARK: stats
    func weekKey(_ d: Date) -> Int { cal.component(.yearForWeekOfYear, from: d) * 100 + cal.component(.weekOfYear, from: d) }
    func bought(week k: Int) -> Int { entries.filter { $0.kind == .buy && weekKey($0.date) == k }.reduce(0) { $0 + $1.bunches } }
    var thisWeekBought: Int { bought(week: weekKey(Date())) }
    var eatDays: Set<Date> { Set(entries.filter { $0.kind == .eat }.map { cal.startOfDay(for: $0.date) }) }
    var ateToday: Bool { eatDays.contains(cal.startOfDay(for: Date())) }
    var totalEats: Int { entries.filter { $0.kind == .eat }.count }
    var totalBunches: Int { entries.filter { $0.kind == .buy }.reduce(0) { $0 + $1.bunches } }

    var streak: Int {
        var d = cal.startOfDay(for: Date()); let days = eatDays
        if !days.contains(d) { d = cal.date(byAdding: .day, value: -1, to: d)! }
        var n = 0
        while days.contains(d) { n += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return n
    }
    var yearWeeks: [Bool] {
        let y = cal.component(.yearForWeekOfYear, from: Date())
        return (1...52).map { bought(week: y * 100 + $0) >= target }
    }
    var weeksDone: Int { yearWeeks.filter { $0 }.count }
    var currentWeek: Int { min(52, cal.component(.weekOfYear, from: Date())) }

    var coins: Int { totalBunches * 10 + totalEats * 5 + streak * 2 + weeksDone * 25 }
    var level: Int { coins / 100 + 1 }
    var levelProgress: Double { Double(coins % 100) / 100 }
    var levelName: String {
        ["Sprout", "Seedling", "Leafy Learner", "Green Gladiator", "Palak Pro", "Methi Master", "Gongura Guru", "Aaku Legend"][min(level - 1, 7)]
    }
    var badges: [Badge] { [
        Badge(id: "1", emoji: "🌱", title: "First Bite", detail: "Eat leaves once", unlocked: totalEats >= 1),
        Badge(id: "2", emoji: "🛒", title: "Shopper", detail: "Buy your first katta", unlocked: totalBunches >= 1),
        Badge(id: "3", emoji: "🔥", title: "3-Day Streak", detail: "Eat 3 days in a row", unlocked: streak >= 3),
        Badge(id: "4", emoji: "⚡️", title: "Week Warrior", detail: "7-day streak", unlocked: streak >= 7),
        Badge(id: "5", emoji: "🏆", title: "Month Master", detail: "30-day streak", unlocked: streak >= 30),
        Badge(id: "6", emoji: "🥬", title: "Green 10", detail: "Eat 10 times", unlocked: totalEats >= 10),
        Badge(id: "7", emoji: "🎯", title: "Weekly Hero", detail: "Hit this week's goal", unlocked: thisWeekBought >= target),
        Badge(id: "8", emoji: "🪙", title: "100 Club", detail: "Earn 100 coins", unlocked: coins >= 100),
        Badge(id: "9", emoji: "🌳", title: "Quarter Champ", detail: "12 goal weeks this year", unlocked: weeksDone >= 12),
        Badge(id: "10", emoji: "👑", title: "Year Legend", detail: "48 goal weeks this year", unlocked: weeksDone >= 48),
    ] }

    var last7: [(String, Int)] {
        (0..<7).reversed().map { i in
            let d = cal.date(byAdding: .day, value: -i, to: Date())!
            let n = entries.filter { $0.kind == .eat && cal.isDate($0.date, inSameDayAs: d) }.count
            return (d.formatted(.dateTime.weekday(.abbreviated)), n)
        }
    }
    var last8Weeks: [(String, Int)] {
        (0..<8).reversed().map { i in
            let d = cal.date(byAdding: .weekOfYear, value: -i, to: Date())!
            return ("W\(cal.component(.weekOfYear, from: d))", bought(week: weekKey(d)))
        }
    }
}
