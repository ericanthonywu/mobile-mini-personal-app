import WidgetKit
import SwiftUI

// MARK: - Models

struct BudgetPeriod: Codable {
    let budget: Int
    let realSpent: Int
    let remaining: Int
    let percentUsed: Int
    let isOverBudget: Bool

    enum CodingKeys: String, CodingKey {
        case budget, realSpent, remaining, percentUsed, isOverBudget
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decodeInt(forKey key: CodingKeys) -> Int {
            if let val = try? container.decode(Int.self, forKey: key) {
                return val
            }
            if let val = try? container.decode(Double.self, forKey: key) {
                return Int(val)
            }
            if let str = try? container.decode(String.self, forKey: key), let val = Double(str) {
                return Int(val)
            }
            return 0
        }

        self.budget = decodeInt(forKey: .budget)
        self.realSpent = decodeInt(forKey: .realSpent)
        self.remaining = decodeInt(forKey: .remaining)
        self.percentUsed = decodeInt(forKey: .percentUsed)
        self.isOverBudget = (try? container.decode(Bool.self, forKey: .isOverBudget)) ?? false
    }

    init(budget: Int, realSpent: Int, remaining: Int, percentUsed: Int, isOverBudget: Bool) {
        self.budget = budget
        self.realSpent = realSpent
        self.remaining = remaining
        self.percentUsed = percentUsed
        self.isOverBudget = isOverBudget
    }
}

struct BudgetSummary: Codable {
    let week: BudgetPeriod
    let month: BudgetPeriod
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let week: BudgetPeriod?
    let month: BudgetPeriod?
    let error: String?

    static var placeholder: WidgetEntry {
        WidgetEntry(
            date: Date(),
            week: BudgetPeriod(budget: 2_000_000, realSpent: 850_000, remaining: 1_150_000, percentUsed: 42, isOverBudget: false),
            month: BudgetPeriod(budget: 8_000_000, realSpent: 4_200_000, remaining: 3_800_000, percentUsed: 52, isOverBudget: false),
            error: nil
        )
    }
}

// MARK: - Keychain helper

struct KeychainHelper {
    static func readToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     "flutter_secure_storage_service",
            kSecAttrAccount as String:     "jwt_token",
            kSecReturnData as String:      true,
            kSecMatchLimit as String:      kSecMatchLimitOne,
            kSecAttrAccessGroup as String: "2L6GH4B3U6.com.ericanthonywu.expenseTracker",
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }
        return token
    }
}

// MARK: - Network

struct BudgetFetcher {
    static var baseURL: String {
        let defaults = UserDefaults(suiteName: "group.com.ericanthonywu.expenseTracker")
        if let savedUrl = defaults?.string(forKey: "base_url"), !savedUrl.isEmpty {
            return savedUrl
        }
        return "http://localhost:3000/api"
    }

    static func fetch(token: String) async throws -> BudgetSummary {
        guard let url = URL(string: "\(baseURL)/budget") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(BudgetSummary.self, from: data)
    }
}

// MARK: - Timeline Provider

struct BudgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        if context.isPreview { completion(.placeholder); return }
        Task { completion(await fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            // Refresh every 30 minutes — iOS throttles for battery efficiency
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> WidgetEntry {
        guard let token = KeychainHelper.readToken() else {
            return WidgetEntry(date: Date(), week: nil, month: nil, error: "Belum login")
        }
        do {
            let summary = try await BudgetFetcher.fetch(token: token)
            return WidgetEntry(date: Date(), week: summary.week, month: summary.month, error: nil)
        } catch {
            return WidgetEntry(date: Date(), week: nil, month: nil, error: "Gagal memuat data")
        }
    }
}

// MARK: - Formatters

extension Int {
    var rupiahCompact: String {
        if self >= 1_000_000 {
            let val = Double(self) / 1_000_000.0
            return String(format: val.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fjt" : "%.1fjt", val)
        } else if self >= 1_000 {
            return String(format: "%.0frb", Double(self) / 1_000.0)
        }
        return "Rp\(self)"
    }

    var rupiah: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = "."
        fmt.groupingSize = 3
        return "Rp" + (fmt.string(from: NSNumber(value: self)) ?? "\(self)")
    }
}

func periodColor(_ p: BudgetPeriod) -> Color {
    if p.isOverBudget  { return .red }
    if p.percentUsed >= 80 { return .orange }
    return .green
}

// MARK: - Period Section (used across sizes)

struct PeriodSection: View {
    let label: String
    let period: BudgetPeriod

    var color: Color { periodColor(period) }
    var progress: Double { min(Double(period.percentUsed) / 100.0, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Label row
            HStack {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
                Spacer()
                Text("\(period.percentUsed)%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15), in: Capsule())
            }

            // Spent amount
            Text(period.realSpent.rupiah)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Budget reference
            Text("dari \(period.budget.rupiah)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Progress bar — native gauge on iOS 26
            ProgressView(value: progress)
                .tint(color)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)

            // Remaining / overage
            Text(period.isOverBudget
                 ? "Lebih \((period.realSpent - period.budget).rupiahCompact)"
                 : "Sisa \(period.remaining.rupiahCompact)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(color.opacity(0.85))
        }
    }
}

// MARK: - Error View

struct WidgetErrorView: View {
    let message: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        if let error = entry.error {
            WidgetErrorView(message: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                    Text("Expense")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
                Spacer()
                if let week = entry.week {
                    PeriodSection(label: "Minggu Ini", period: week)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        if let error = entry.error {
            WidgetErrorView(message: error)
        } else {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                            .font(.caption2)
                            .foregroundStyle(.tint)
                        Text("Expense Tracker")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                    Spacer()
                    if let week = entry.week {
                        PeriodSection(label: "Minggu Ini", period: week)
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 0) {
                    Text(shortDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    if let month = entry.month {
                        PeriodSection(label: "Bulan Ini", period: month)
                    }
                }
            }
            .padding(14)
        }
    }

    var shortDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: "id_ID")
        return fmt.string(from: entry.date)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        if let error = entry.error {
            WidgetErrorView(message: error)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    Label("Expense Tracker", systemImage: "creditcard.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Spacer()
                    Text(dateTimeString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                if let week = entry.week {
                    PeriodSection(label: "Minggu Ini", period: week)
                }

                Divider()

                if let month = entry.month {
                    PeriodSection(label: "Bulan Ini", period: month)
                }

                Spacer()

                // Last updated
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text("Diperbarui \(timeString)")
                        .font(.caption2)
                }
                .foregroundStyle(.quaternary)
            }
            .padding(16)
        }
    }

    var dateTimeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, d MMM"
        fmt.locale = Locale(identifier: "id_ID")
        return fmt.string(from: entry.date)
    }

    var timeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: entry.date)
    }
}

// MARK: - Lock Screen Widget Views

struct LockScreenRectangularView: View {
    let entry: WidgetEntry

    var body: some View {
        if let week = entry.week, let month = entry.month {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 9))
                    Text("EXPENSE")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(.secondary)
                
                HStack {
                    Text("Minggu:")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text(week.realSpent.rupiahCompact)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                
                HStack {
                    Text("Bulan:")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text(month.realSpent.rupiahCompact)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
        } else {
            Text("Expense Tracker")
                .font(.caption2)
        }
    }
}

struct LockScreenCircularView: View {
    let entry: WidgetEntry

    var body: some View {
        if let week = entry.week {
            Gauge(value: min(Double(week.percentUsed) / 100.0, 1.0)) {
                Image(systemName: "creditcard.fill")
            } currentValueLabel: {
                Text("\(week.percentUsed)%")
                    .font(.system(size: 10, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Image(systemName: "creditcard.fill")
        }
    }
}

struct LockScreenInlineView: View {
    let entry: WidgetEntry

    var body: some View {
        if let week = entry.week, let month = entry.month {
            Text("Mgg: \(week.realSpent.rupiahCompact) • Bln: \(month.realSpent.rupiahCompact)")
        } else {
            Text("Expense Tracker")
        }
    }
}

// MARK: - Entry View dispatcher

struct ExpenseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:           SmallWidgetView(entry: entry)
            case .systemMedium:          MediumWidgetView(entry: entry)
            case .systemLarge:           LargeWidgetView(entry: entry)
            case .accessoryRectangular:  LockScreenRectangularView(entry: entry)
            case .accessoryCircular:     LockScreenCircularView(entry: entry)
            case .accessoryInline:       LockScreenInlineView(entry: entry)
            default:                     MediumWidgetView(entry: entry)
            }
        }
        .containerBackground(.regularMaterial, for: .widget)
    }
}

// MARK: - Widget Configuration

struct ExpenseWidget: Widget {
    let kind: String = "ExpenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetTimelineProvider()) { entry in
            ExpenseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Expense Tracker")
        .description("Pantau pengeluaran minggu dan bulan ini.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
