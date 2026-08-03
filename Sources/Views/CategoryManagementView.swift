import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReceiptCategory.sortOrder) private var categories: [ReceiptCategory]

    @State private var newCategoryName = ""
    @State private var isShowingDeleteAlert = false
    @State private var categoryPendingDeletion: ReceiptCategory?

    var body: some View {
        NavigationStack {
            Form {
                Section("新增分類") {
                    HStack {
                        TextField("分類名稱", text: $newCategoryName)
                        Button("新增") {
                            addCategory()
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("現有分類") {
                    ForEach(categories) { category in
                        HStack {
                            Label(category.name, systemImage: category.symbolName)
                            Spacer()
                            if category.isDefault {
                                Text("預設").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            if !category.isDefault {
                                Button(role: .destructive) {
                                    categoryPendingDeletion = category
                                    isShowingDeleteAlert = true
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("管理分類")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .confirmationDialog("確定要刪除這個分類嗎？使用此分類的收據會改標記為「未分類」。", isPresented: $isShowingDeleteAlert, titleVisibility: .visible) {
                Button("刪除", role: .destructive) { deleteCategory() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !categories.contains(where: { $0.name == trimmed }) else {
            newCategoryName = ""
            return
        }
        let nextOrder = (categories.map(\.sortOrder).max() ?? 0) + 1
        let category = ReceiptCategory(name: trimmed, symbolName: "tag", isDefault: false, sortOrder: nextOrder)
        modelContext.insert(category)
        try? modelContext.save()
        newCategoryName = ""
    }

    private func deleteCategory() {
        guard let category = categoryPendingDeletion else { return }

        let descriptor = FetchDescriptor<Receipt>(predicate: #Predicate { $0.categoryName == category.name })
        if let affectedReceipts = try? modelContext.fetch(descriptor) {
            for receipt in affectedReceipts {
                receipt.categoryName = "未分類"
            }
        }

        modelContext.delete(category)
        try? modelContext.save()
        categoryPendingDeletion = nil
    }
}

#Preview {
    CategoryManagementView()
        .modelContainer(for: [Receipt.self, ReceiptCategory.self], inMemory: true)
}
