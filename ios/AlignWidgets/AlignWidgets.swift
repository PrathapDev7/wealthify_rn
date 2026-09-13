import WidgetKit
import SwiftUI

private let appGroupId = "group.com.invent.wealthify"

private func store() -> UserDefaults? {
    UserDefaults(suiteName: appGroupId)
}

private func s(_ key: String, fallback: String = "—") -> String {
    store()?.string(forKey: key) ?? fallback
}

private func i(_ key: String) -> Int {
    let d = store()
    if let n = d?.object(forKey: key) as? NSNumber { return n.intValue }
    return d?.integer(forKey: key) ?? 0
}

private func widgetUrl(_ screen: String) -> URL {
    URL(string: "align://widget?homeWidget=\(screen)")!
}

struct AlignEntry: TimelineEntry {
    let date: Date
}

struct AlignProvider: TimelineProvider {
    func placeholder(in context: Context) -> AlignEntry { AlignEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (AlignEntry) -> Void) {
        completion(AlignEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AlignEntry>) -> Void) {
        let entry = AlignEntry(date: Date())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

private struct WidgetCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(red: 0x14/255.0, green: 0x1B/255.0, blue: 0x2E/255.0))
            .cornerRadius(16)
    }
}

private struct Label: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
    }
}

private struct Bar: View {
    let progress: Int
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0x23/255.0, green: 0x30/255.0, blue: 0x4D/255.0))
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0x3D/255.0, green: 0xDC/255.0, blue: 0x84/255.0))
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 100)) / 100.0)
            }
        }
        .frame(height: 6)
    }
}

struct AlignBalanceView: View {
    var body: some View {
        WidgetCard {
            VStack(alignment: .leading, spacing: 2) {
                Label("Balance")
                Text(s("align_balance_text"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(s("align_balance_sub", fallback: "Open Align to sync"))
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
                Spacer(minLength: 6)
                HStack {
                    Text(s("align_spent_text"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("of \(s("align_spent_of"))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
                }
                Bar(progress: i("align_spent_progress"))
            }
        }
        .widgetURL(widgetUrl("balance"))
    }
}

private struct BudgetRow: View {
    let name: String
    let spent: Double
    let limit: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text(remainingText)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
            }
            Bar(progress: pct)
        }
        .padding(8)
        .background(Color(red: 0x23/255.0, green: 0x30/255.0, blue: 0x4D/255.0))
        .cornerRadius(10)
    }
    private var remaining: Double { limit - spent }
    private var remainingText: String {
        remaining < 0 ? "\(fmt(-remaining)) over" : "\(fmt(remaining)) left"
    }
    private var pct: Int {
        guard limit > 0 else { return 0 }
        return min(max(Int((spent / limit * 100).rounded()), 0), 100)
    }
    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

private func budgetRows() -> [(String, Double, Double)] {
    let raw = s("align_budget_rows", fallback: "")
    return raw.split(separator: ";").compactMap { part in
        let p = part.split(separator: "|", omittingEmptySubsequences: false)
        guard p.count == 3 else { return nil }
        return (String(p[0]), Double(p[1]) ?? 0, Double(p[2]) ?? 0)
    }
}

struct AlignBudgetsView: View {
    var body: some View {
        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                Label("Budgets")
                let rows = budgetRows()
                if rows.isEmpty {
                    Text("Open Align to sync")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                } else {
                    ForEach(rows, id: \.0) { row in
                        BudgetRow(name: row.0, spent: row.1, limit: row.2)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(widgetUrl("budgets"))
    }
}

struct AlignCaloriesView: View {
    var body: some View {
        WidgetCard {
            VStack(alignment: .leading, spacing: 4) {
                Label("Calories today")
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(i("align_cal_consumed"))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("kcal")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
                    Spacer()
                    Text(calLeftText)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0x3D/255.0, green: 0xDC/255.0, blue: 0x84/255.0))
                }
                Bar(progress: i("align_cal_progress"))
                Spacer(minLength: 6)
                HStack(spacing: 6) {
                    MacroChip(text: "P \(i("align_cal_protein"))/\(i("align_cal_protein_target"))g")
                    MacroChip(text: "C \(i("align_cal_carbs"))/\(i("align_cal_carbs_target"))g")
                    MacroChip(text: "F \(i("align_cal_fat"))/\(i("align_cal_fat_target"))g")
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(widgetUrl("calories"))
    }
    private var calLeftText: String {
        let target = i("align_cal_target")
        guard target > 0 else { return "" }
        let left = i("align_cal_left")
        return left < 0 ? "\(-left) over" : "\(left) left"
    }
}

private struct MacroChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(.white)
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0x23/255.0, green: 0x30/255.0, blue: 0x4D/255.0))
            .cornerRadius(8)
    }
}

struct AlignFitnessView: View {
    var body: some View {
        WidgetCard {
            VStack(alignment: .leading, spacing: 4) {
                Label("Training today")
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(i("align_fit_minutes"))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("min")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
                    Spacer()
                    Text(s("align_fit_today_label", fallback: ""))
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0x9A/255.0, green: 0xA5/255.0, blue: 0xC4/255.0))
                }
                Spacer(minLength: 6)
                HStack(spacing: 6) {
                    MacroChip(text: "\(i("align_fit_workouts")) workouts")
                    MacroChip(text: "\(i("align_fit_sets")) sets")
                    MacroChip(text: s("align_fit_volume", fallback: "0 kg"))
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(widgetUrl("fitness"))
    }
}

@main
struct AlignWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AlignBalanceWidget()
        AlignBudgetsWidget()
        AlignCaloriesWidget()
        AlignFitnessWidget()
    }
}

struct AlignBalanceWidget: Widget {
    let kind = "AlignBalance"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlignProvider()) { _ in
            AlignBalanceView()
        }
        .configurationDisplayName("Align Balance")
        .description("Balance snapshot with month spend.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AlignBudgetsWidget: Widget {
    let kind = "AlignBudgets"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlignProvider()) { _ in
            AlignBudgetsView()
        }
        .configurationDisplayName("Align Budgets")
        .description("Top category budgets with remaining amounts.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AlignCaloriesWidget: Widget {
    let kind = "AlignCalories"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlignProvider()) { _ in
            AlignCaloriesView()
        }
        .configurationDisplayName("Align Calories")
        .description("Today's calories with macros.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AlignFitnessWidget: Widget {
    let kind = "AlignFitness"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlignProvider()) { _ in
            AlignFitnessView()
        }
        .configurationDisplayName("Align Fitness")
        .description("Today's training at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
