import Foundation

/// 從 OCR 文字結構化解析後的收據欄位，不論來源是 AI 或規則式解析都會統一成這個型別。
struct ParsedReceipt {
    var merchantName: String
    var transactionDate: Date
    var totalAmount: Decimal
    var taxAmount: Decimal?
    var currencyCode: String
    var suggestedCategory: String
    /// true 代表這筆結果是由裝置端 AI（Apple Foundation Models）產生
    var usedAI: Bool
}
