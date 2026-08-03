import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let receipt: Receipt

    @State private var isShowingEdit = false
    @State private var isShowingDeleteConfirm = false
    @State private var isShowingRawText = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = ImageStorageService().loadImage(fileName: receipt.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(receipt.merchantName)
                        .font(.title2.bold())

                    Text(Self.dateFormatter.string(from: receipt.transactionDate))
                        .foregroundStyle(.secondary)

                    HStack {
                        Label(receipt.categoryName, systemImage: "tag")
                        Spacer()
                        if receipt.wasParsedByAI {
                            Label("AI 辨識", systemImage: "sparkles")
                                .foregroundStyle(.blue)
                        }
                    }
                    .font(.subheadline)
                }

                Divider()

                VStack(spacing: 12) {
                    detailRow(title: "總金額", value: CurrencyFormatter.format(amount: receipt.totalAmount, currencyCode: receipt.currencyCode))
                    if let tax = receipt.taxAmount {
                        detailRow(title: "稅額", value: CurrencyFormatter.format(amount: tax, currencyCode: receipt.currencyCode))
                    }
                }

                if !receipt.note.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("備註").font(.headline)
                        Text(receipt.note)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                DisclosureGroup("查看 OCR 原始文字", isExpanded: $isShowingRawText) {
                    Text(receipt.rawOCRText.isEmpty ? "（無辨識結果）" : receipt.rawOCRText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("收據詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isShowingEdit = true
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        isShowingDeleteConfirm = true
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("確定要刪除這筆收據嗎？", isPresented: $isShowingDeleteConfirm, titleVisibility: .visible) {
            Button("刪除", role: .destructive) { deleteReceipt() }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingEdit) {
            if let image = ImageStorageService().loadImage(fileName: receipt.imageFileName) {
                let draft = ReceiptDraft(
                    image: image,
                    parsed: ParsedReceipt(
                        merchantName: receipt.merchantName,
                        transactionDate: receipt.transactionDate,
                        totalAmount: receipt.totalAmount,
                        taxAmount: receipt.taxAmount,
                        currencyCode: receipt.currencyCode,
                        suggestedCategory: receipt.categoryName,
                        usedAI: receipt.wasParsedByAI
                    ),
                    rawOCRText: receipt.rawOCRText
                )
                ReceiptEditView(draft: draft, existingReceipt: receipt) {
                    isShowingEdit = false
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.headline).monospacedDigit()
        }
    }

    private func deleteReceipt() {
        ImageStorageService().deleteImage(fileName: receipt.imageFileName)
        modelContext.delete(receipt)
        try? modelContext.save()
        dismiss()
    }
}
