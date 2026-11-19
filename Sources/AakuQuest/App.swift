import SwiftUI
import Charts

@main
struct AakuQuestApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store).frame(minWidth: 560, minHeight: 680)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "leaf.fill") }
            YearView().tabItem { Label("Year", systemImage: "calendar") }
            BadgesView().tabItem { Label("Badges", systemImage: "rosette") }
            ReportView().tabItem { Label("Reports", systemImage: "chart.bar.fill") }
            WhyView().tabItem { Label("Why", systemImage: "heart.fill") }
        }.padding()
    }
}

struct TodayView: View {
    @EnvironmentObject var s: Store
    @AppStorage("why") private var why = ""
    @State private var bounce = false
    @State private var popup: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 18) {
                    Text("🥬").font(.system(size: 90))
                        .offset(y: bounce ? -10 : 6)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: bounce)
                    Text("Level \(s.level) · \(s.levelName)").font(.title2.bold())
                    ProgressView(value: s.levelProgress).tint(.green).frame(maxWidth: 320)
                    HStack(spacing: 30) {
                        stat("🪙", "\(s.coins)", "coins")
                        stat("🔥", "\(s.streak)", "day streak")
                        stat("🛒", "\(s.thisWeekBought)/\(s.target)", "katta this week")
                    }
                    Text(s.ateToday ? "✅ You ate your aaku today. Super!" : "🍽️ Haven't eaten aaku yet today!")
                        .font(.headline)
                    HStack {
                        Button("🛒 Bought 1 katta") { log(.buy, 1, "+10 🪙") }
                        Button("🛒🛒 Bought 2 katta") { log(.buy, 2, "+20 🪙") }
                        Button("🍽️ Ate today") { log(.eat, 1, "+5 🪙 🔥") }.tint(.green)
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                    Picker("Weekly goal", selection: $s.target) {
                        Text("1 katta / week").tag(1); Text("2 katta / week").tag(2)
                    }.pickerStyle(.segmented).frame(maxWidth: 320)
                    if !why.isEmpty {
                        Text("💚 \(why)").padding().background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    }
                }.padding()
            }
            if let p = popup {
                Text(p).font(.largeTitle.bold()).padding(.horizontal, 24).padding(.vertical, 10)
                    .background(.yellow, in: Capsule()).shadow(radius: 6)
                    .transition(.move(edge: .bottom).combined(with: .scale).combined(with: .opacity))
            }
        }.onAppear { bounce = true }
    }
    func stat(_ e: String, _ v: String, _ l: String) -> some View {
        VStack { Text(e).font(.largeTitle); Text(v).font(.title.bold()); Text(l).font(.caption).foregroundStyle(.secondary) }
    }
    func log(_ k: Kind, _ n: Int, _ text: String) {
        s.add(k, n)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { popup = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { withAnimation { popup = nil } }
    }
}

struct YearView: View {
    @EnvironmentObject var s: Store
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 My Year Plan").font(.title.bold())
            Text("Goal: buy \(s.target) katta every week. Green = goal done. \(s.weeksDone)/52 weeks complete.")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 13), spacing: 8) {
                ForEach(0..<52, id: \.self) { i in
                    ZStack {
                        Circle().fill(s.yearWeeks[i] ? Color.green : Color.gray.opacity(0.2))
                        if i + 1 == s.currentWeek { Circle().stroke(Color.orange, lineWidth: 3) }
                        Text("\(i + 1)").font(.caption2).foregroundStyle(s.yearWeeks[i] ? .white : .secondary)
                    }.aspectRatio(1, contentMode: .fit)
                }
            }
            Text("Orange ring = this week. Each goal week = +25 🪙").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding()
    }
}

struct BadgesView: View {
    @EnvironmentObject var s: Store
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 14) {
                ForEach(s.badges) { b in
                    VStack(spacing: 4) {
                        Text(b.emoji).font(.system(size: 46)).grayscale(b.unlocked ? 0 : 1).opacity(b.unlocked ? 1 : 0.35)
                        Text(b.title).bold(); Text(b.detail).font(.caption).foregroundStyle(.secondary)
                        if b.unlocked { Text("Unlocked ✓").font(.caption).foregroundStyle(.green) }
                    }.frame(maxWidth: .infinity).padding()
                    .background(b.unlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }.padding()
        }
    }
}

struct ReportView: View {
    @EnvironmentObject var s: Store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("📊 Reports").font(.title.bold())
                Text("Total: \(s.totalBunches) katta bought · \(s.totalEats) times eaten · \(s.coins) coins")
                Text("Eaten – last 7 days").font(.headline)
                Chart(s.last7, id: \.0) { BarMark(x: .value("Day", $0.0), y: .value("Times", $0.1)).foregroundStyle(.green) }.frame(height: 160)
                Text("Katta bought – last 8 weeks").font(.headline)
                Chart(s.last8Weeks, id: \.0) { BarMark(x: .value("Week", $0.0), y: .value("Katta", $0.1)).foregroundStyle(.orange) }.frame(height: 160)
            }.padding()
        }
    }
}

struct WhyView: View {
    @AppStorage("why") private var why = ""
    let benefits = [
        ("🩸", "Iron & folate", "Palakura, gongura, thotakura help fight tiredness and low blood."),
        ("🦴", "Vitamin K & calcium", "Stronger bones; methi and amaranth are great."),
        ("👀", "Vitamin A", "Good for eyes and skin."),
        ("🫄", "Fibre", "Better digestion, less constipation."),
        ("❤️", "Heart friendly", "Low calories, potassium and antioxidants."),
        ("🛡️", "Immunity", "Vitamin C and plant power for a stronger body."),
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("💚 Why am I doing this?").font(.title.bold())
                TextField("Write your own reason (shown on Today)…", text: $why).textFieldStyle(.roundedBorder)
                Text("Benefits of eating aaku kuralu").font(.headline).padding(.top, 8)
                ForEach(benefits, id: \.1) { b in
                    HStack(alignment: .top) { Text(b.0).font(.title); VStack(alignment: .leading) { Text(b.1).bold(); Text(b.2).foregroundStyle(.secondary) } }
                }
                Text("Try: thotakura, palakura, gongura, menthi kura, chukkakura, kothimeera, pudina 🌿").padding(.top, 8)
            }.padding()
        }
    }
}
