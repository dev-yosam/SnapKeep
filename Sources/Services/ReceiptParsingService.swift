import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// 負責把 OCR 出來的原始文字，轉成結構化的收據欄位。
///
/// 優先使用 Apple Foundation Models（裝置端 Apple Intelligence 大型語言模型）；
/// 若裝置不支援（例如非 Apple Intelligence 機型、系統版本過舊、或功能被使用者關閉），
/// 會自動退回到不需要 AI 的規則式解析器，確保 App 在任何裝置上都能正常使用。
///
/// 全程沒有任何網路請求：Foundation Models 的推論在裝置本機執行，規則式解析純粹是字串比對。
final class ReceiptParsingService {

    private let fallbackParser = RuleBasedReceiptParser()

    func parse(ocrText: String) async -> ParsedReceipt {
        if let aiResult = await parseWithFoundationModel(ocrText: ocrText) {
            return aiResult
        }
        return fallbackParser.parse(ocrText: ocrText)
    }

    /// 回傳目前裝置是否可以使用裝置端 AI 做結構化解析（僅供 UI 顯示用途，例如提示使用者升級系統）。
    func isOnDeviceAIAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            default:
                return false
            }
        }
        #endif
        return false
    }

    private func parseWithFoundationModel(ocrText: String) async -> ParsedReceipt? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return nil }
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        let session = LanguageModelSession(instructions: """
        你是一個專門解析收據 OCR 文字的助手。使用者會提供一張收據透過文字辨識取得的原始內容，
        內容可能包含雜訊、換行錯亂或辨識錯誤。請盡力從中萃取正確的結構化欄位，
        所有輸出都必須根據提供的文字內容判斷，絕對不要憑空捏造未出現在文字中的資訊。
        """)

        let prompt = """
        以下是一張收據的 OCR 辨識原始文字，請萃取出商家名稱、交易日期、總金額、稅額、貨幣代碼與建議分類：

        ---
        \(ocrText)
        ---
        """

        do {
            let response = try await session.respond(to: prompt, generating: AIReceiptFields.self)
            let fields = response.content

            let merchantName = fields.merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
            let currencyCode = fields.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let category = fields.suggestedCategory.trimmingCharacters(in: .whitespacesAndNewlines)

            return ParsedReceipt(
                merchantName: merchantName.isEmpty ? "未知商家" : merchantName,
                transactionDate: DateParsing.parseFlexibleDate(fields.transactionDate)
                    ?? DateParsing.firstDetectedDate(in: ocrText)
                    ?? .now,
                totalAmount: Decimal(fields.totalAmount),
                taxAmount: fields.taxAmount > 0 ? Decimal(fields.taxAmount) : nil,
                currencyCode: currencyCode.isEmpty ? "TWD" : currencyCode,
                suggestedCategory: category.isEmpty ? "未分類" : category,
                usedAI: true
            )
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}
