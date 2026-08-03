import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReceiptCategory.sortOrder) private var categories: [ReceiptCategory]

    var body: some View {
        TabView {
            ReceiptListView()
                .tabItem {
                    Label("收據", systemImage: "receipt")
                }

            DashboardView()
                .tabItem {
                    Label("儀表板", systemImage: "chart.pie.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .task {
            seedDefaultCategoriesIfNeeded()
        }
    }

    private func seedDefaultCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for category in ReceiptCategory.defaultCategories {
            modelContext.insert(category)
        }
        try? modelContext.save()
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Receipt.self, ReceiptCategory.self], inMemory: true)
}
