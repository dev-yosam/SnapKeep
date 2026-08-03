import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var receipts: [Receipt]

    @State private var isShowingCategoryManagement = false
    @State private var isShowingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isShowingClearConfirm = false
    @State private var isShowingClearedAlert = false

    private let parsingService = ReceiptParsingService()

    var body: some View {
        NavigationStack {
            Form {
                Section("裝置端 AI") {
                    HStack {
                        Image(systemName: parsingService.isOnDeviceAIAvailable() ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(parsingService.isOnDeviceAIAvailable() ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(parsingService.isOnDeviceAIAvailable() ? "裝置端 AI 已啟用" : "裝置端 AI 未啟用")
                                .font(.subheadline)
                            Text("需要支援 Apple Intelligence 的機型與系統版本，未啟用時會改用基本規則辨識。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("分類") {
                    Button {
                        isShowingCategoryManagement = true
                    } label: {
                        Label("管理分類", systemImage: "tag")
                    }
                }

                Section("資料") {
                    Button {
                        exportCSV()
                    } label: {
                        Label("匯出成 CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(receipts.isEmpty)

                    Button(role: .destructive) {
                        isShowingClearConfirm = true
                    } label: {
                        Label("清除所有資料", systemImage: "trash")
                    }
                    .disabled(receipts.isEmpty)
                }

                Section("關於") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("快拍收據夾 SnapKeep")
                            .font(.headline)
                        Text("""
                        100% 離線・不需要帳號・不使用雲端・沒有訂閱制。

                        所有照片辨識與 AI 分析都在你的裝置上完成，資料只會儲存在這支手機裡，\
                        沒有後端伺服器，也不會有任何網路傳輸。
                        """)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $isShowingCategoryManagement) {
                CategoryManagementView()
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let exportedFileURL {
                    ActivityShareSheet(items: [exportedFileURL])
                }
            }
            .confirmationDialog("確定要清除所有收據資料嗎？此動作無法復原。", isPresented: $isShowingClearConfirm, titleVisibility: .visible) {
                Button("清除所有資料", role: .destructive) { clearAllData() }
                Button("取消", role: .cancel) {}
            }
            .alert("已清除所有資料", isPresented: $isShowingClearedAlert) {
                Button("好", role: .cancel) {}
            }
        }
    }

    private func exportCSV() {
        let csv = ExportService.makeCSV(from: receipts)
        if let url = try? ExportService.writeTemporaryCSVFile(csv: csv) {
            exportedFileURL = url
            isShowingShareSheet = true
        }
    }

    private func clearAllData() {
        let imageStorage = ImageStorageService()
        for receipt in receipts {
            imageStorage.deleteImage(fileName: receipt.imageFileName)
            modelContext.delete(receipt)
        }
        try? modelContext.save()
        isShowingClearedAlert = true
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Receipt.self, ReceiptCategory.self], inMemory: true)
}
