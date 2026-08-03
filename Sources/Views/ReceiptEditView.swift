import SwiftUI
import SwiftData

struct ReceiptEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReceiptCategory.sortOrder) private var categories: [ReceiptCategory]

    let draft: ReceiptDraft
    let onFinished: () -> Void

    @State private var merchantName: String
    @State private var transactionDate: Date
    @State private var amountText: String
    @State private var taxText: String
    @State private var currencyCode: String
    @State private var categoryName: String
    @State private var note: String
    @State private var isSaving = false

    private let existingReceipt: Receipt?

    init(draft: ReceiptDraft, existingReceipt: Receipt? = nil, onFinished: @escaping () -> Void) {
        self.draft = draft
        self.existingReceipt = existingReceipt
        self.onFinished = onFinished
        _merchantName = State(initialValue: draft.parsed.merchantName)
        _transactionDate = State(initialValue: draft.parsed.transactionDate)
        _amountText = State(initialValue: Self.decimalToString(draft.parsed.totalAmount))
        _taxText = State(initialValue: draft.parsed.taxAmount.map(Self.decimalToString) ?? "")
        _currencyCode = State(initialValue: draft.parsed.currencyCode)
        _categoryName = State(initialValue: draft.parsed.suggestedCategory)
        _note = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(uiImage: draft.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                        .padding(8)
                }

                if draft.parsed.usedAI {
                    Label("已使用裝置端 AI 自動辨識，請確認內容是否正確", systemImage: "sparkles")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Label("目前裝置無法使用裝置端 AI，已用基本規則辨識，請手動確認金額與商家", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("基本資訊") {
                    TextField("商家名稱", text: $merchantName)
                    DatePicker("交易日期", selection: $transactionDate, displayedComponents: .date)

                    Picker("分類", selection: $categoryName) {
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.symbolName)
                                .tag(category.name)
                        }
                    }
                }

                Section("金額") {
                    HStack {
                        TextField("總金額", text: $amountText)
                            .keyboardType(.decimalPad)
                        TextField("幣別", text: $currencyCode)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                    }
                    HStack {
                        Text("稅額（選填）")
                        Spacer()
                        TextField("0", text: $taxText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }

                Section("備註") {
                    TextField("備註", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("OCR 原始文字") {
                    Text(draft.rawOCRText.isEmpty ? "（無辨識結果）" : draft.rawOCRText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(existingReceipt == nil ? "新增收據" : "編輯收據")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onFinished()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        save()
                    }
                    .disabled(isSaving || merchantName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: "")) ?? 0
        let tax = taxText.isEmpty ? nil : Decimal(string: taxText.replacingOccurrences(of: ",", with: ""))

        do {
            if let existingReceipt {
                existingReceipt.merchantName = merchantName
                existingReceipt.transactionDate = transactionDate
                existingReceipt.totalAmount = amount
                existingReceipt.taxAmount = tax
                existingReceipt.currencyCode = currencyCode.uppercased()
                existingReceipt.categoryName = categoryName
                existingReceipt.note = note
                existingReceipt.updatedAt = .now
            } else {
                let imageFileName = try ImageStorageService().saveImage(draft.image)
                let receipt = Receipt(
                    merchantName: merchantName,
                    transactionDate: transactionDate,
                    totalAmount: amount,
                    currencyCode: currencyCode.uppercased(),
                    taxAmount: tax,
                    categoryName: categoryName,
                    note: note,
                    rawOCRText: draft.rawOCRText,
                    imageFileName: imageFileName,
                    wasParsedByAI: draft.parsed.usedAI
                )
                modelContext.insert(receipt)
            }
            try modelContext.save()
            onFinished()
            dismiss()
        } catch {
            isSaving = false
        }
    }

    private static func decimalToString(_ value: Decimal) -> String {
        guard value != 0 else { return "" }
        return NSDecimalNumber(decimal: value).stringValue
    }
}
