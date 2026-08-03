import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Query(sort: \Receipt.transactionDate, order: .reverse) private var receipts: [Receipt]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedCategoryFilter: String? = nil
    @State private var isShowingSourcePicker = false
    @State private var isShowingCamera = false
    @State private var isShowingPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var pendingReceiptDraft: ReceiptDraft?

    private var filteredReceipts: [Receipt] {
        receipts.filter { receipt in
            let matchesSearch = searchText.isEmpty
                || receipt.merchantName.localizedCaseInsensitiveContains(searchText)
                || receipt.note.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategoryFilter == nil || receipt.categoryName == selectedCategoryFilter
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if receipts.isEmpty {
                    emptyState
                } else {
                    receiptList
                }
            }
            .navigationTitle("快拍收據夾")
            .searchable(text: $searchText, prompt: "搜尋商家或備註")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingSourcePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .confirmationDialog("新增收據", isPresented: $isShowingSourcePicker, titleVisibility: .visible) {
                Button("拍照") { isShowingCamera = true }
                Button("從相簿選擇") { isShowingPhotoLibrary = true }
                Button("取消", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                ImagePickerView(sourceType: .camera) { image in
                    isShowingCamera = false
                    if let image { capturedImage = image }
                }
            }
            .sheet(isPresented: $isShowingPhotoLibrary) {
                PhotoLibraryPickerView { image in
                    isShowingPhotoLibrary = false
                    if let image { capturedImage = image }
                }
            }
            .fullScreenCover(item: $capturedImage.asIdentifiableImage) { identifiableImage in
                ScanningView(image: identifiableImage.image) { draft in
                    capturedImage = nil
                    pendingReceiptDraft = draft
                } onCancel: {
                    capturedImage = nil
                }
            }
            .sheet(item: $pendingReceiptDraft) { draft in
                ReceiptEditView(draft: draft) {
                    pendingReceiptDraft = nil
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("還沒有任何收據", systemImage: "receipt")
        } description: {
            Text("點右上角的「+」拍照或從相簿選擇收據，AI 會自動幫你辨識金額與商家。")
        }
    }

    private var receiptList: some View {
        List {
            ForEach(filteredReceipts) { receipt in
                NavigationLink(value: receipt) {
                    ReceiptRowView(receipt: receipt)
                }
            }
            .onDelete(perform: deleteReceipts)
        }
        .listStyle(.plain)
        .navigationDestination(for: Receipt.self) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        let imageStorage = ImageStorageService()
        for index in offsets {
            let receipt = filteredReceipts[index]
            imageStorage.deleteImage(fileName: receipt.imageFileName)
            modelContext.delete(receipt)
        }
        try? modelContext.save()
    }
}

/// 用來讓拍照/選圖後的暫存資料在 sheet 之間傳遞的草稿模型。
struct ReceiptDraft: Identifiable {
    let id = UUID()
    var image: UIImage
    var parsed: ParsedReceipt
    var rawOCRText: String
}

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private extension Binding where Value == UIImage? {
    var asIdentifiableImage: Binding<IdentifiableImage?> {
        Binding<IdentifiableImage?>(
            get: { wrappedValue.map(IdentifiableImage.init) },
            set: { newValue in wrappedValue = newValue?.image }
        )
    }
}

#Preview {
    ReceiptListView()
        .modelContainer(for: [Receipt.self, ReceiptCategory.self], inMemory: true)
}
