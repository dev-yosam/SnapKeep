import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var receipts: [Receipt]

    @State private var selectedMonthOffset = 0

    private var calendar: Calendar { .current }

    private var selectedMonthDate: Date {
        calendar.date(byAdding: .month, value: selectedMonthOffset, to: .now) ?? .now
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: selectedMonthDate)
    }

    private var receiptsInSelectedMonth: [Receipt] {
        receipts.filter { calendar.isDate($0.transactionDate, equalTo: selectedMonthDate, toGranularity: .month) }
    }

    private var totalSpent: Decimal {
        receiptsInSelectedMonth.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }

    private struct CategorySpend: Identifiable {
        let id = UUID()
        let category: String
        let amount: Decimal
    }

    private var categorySpends: [CategorySpend] {
        let grouped = Dictionary(grouping: receiptsInSelectedMonth, by: \.categoryName)
        return grouped.map { CategorySpend(category: $0.key, amount: $0.value.reduce(Decimal(0)) { $0 + $1.totalAmount }) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    monthSelector

                    VStack(spacing: 4) {
                        Text("本月總支出")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(amount: totalSpent, currencyCode: dominantCurrencyCode()))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    if categorySpends.isEmpty {
                        ContentUnavailableView("這個月還沒有資料", systemImage: "chart.pie")
                            .frame(height: 200)
                    } else {
                        chartSection
                        categoryBreakdownList
                    }
                }
                .padding()
            }
            .navigationTitle("儀表板")
        }
    }

    private var monthSelector: some View {
        HStack {
            Button {
                selectedMonthOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthLabel)
                .font(.headline)
            Spacer()
            Button {
                selectedMonthOffset += 1
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedMonthOffset >= 0)
        }
        .padding(.horizontal, 8)
    }

    private var chartSection: some View {
        Chart(categorySpends) { item in
            SectorMark(
                angle: .value("金額", (item.amount as NSDecimalNumber).doubleValue),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("分類", item.category))
            .cornerRadius(4)
        }
        .frame(height: 220)
    }

    private var categoryBreakdownList: some View {
        VStack(spacing: 0) {
            ForEach(categorySpends) { item in
                HStack {
                    Text(item.category)
                    Spacer()
                    Text(CurrencyFormatter.format(amount: item.amount, currencyCode: dominantCurrencyCode()))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                Divider()
            }
        }
    }

    private func dominantCurrencyCode() -> String {
        let counts = Dictionary(grouping: receiptsInSelectedMonth, by: \.currencyCode).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "TWD"
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Receipt.self, ReceiptCategory.self], inMemory: true)
}
