import Foundation

/// 不需要任何 AI 模型、單純用關鍵字與正規表示式從 OCR 文字萃取欄位的備援解析器。
/// 用於裝置不支援 Apple Intelligence（Foundation Models）時，仍能提供基本可用的體驗。
struct RuleBasedReceiptParser {

    private static let totalKeywords = [
        "總計", "合計", "應付金額", "應付總額", "消費金額", "總金額", "total", "amount due", "grand total", "balance due"
    ]

    func parse(ocrText: String) -> ParsedReceipt {
        let lines = ocrText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let merchantName = guessMerchantName(from: lines)
        let totalAmount = Self.extractTotalAmount(fromLines: lines) ?? 0
        let transactionDate = DateParsing.firstDetectedDate(in: ocrText) ?? .now
        let currencyCode = Self.extractCurrencyCode(from: ocrText) ?? "TWD"

        return ParsedReceipt(
            merchantName: merchantName,
            transactionDate: transactionDate,
            totalAmount: totalAmount,
            taxAmount: nil,
            currencyCode: currencyCode,
            suggestedCategory: "未分類",
            usedAI: false
        )
    }

    /// 收據最上方通常是店名，取第一行非空、非純數字的文字作為店名猜測。
    private func guessMerchantName(from lines: [String]) -> String {
        for line in lines.prefix(5) {
            let digitsOnly = line.allSatisfy { $0.isNumber || $0.isWhitespace || $0.isPunctuation }
            if !digitsOnly && line.count >= 2 {
                return line
            }
        }
        return "未知商家"
    }

    private static func extractTotalAmount(fromLines lines: [String]) -> Decimal? {
        for line in lines {
            let lower = line.lowercased()
            if totalKeywords.contains(where: { lower.contains($0.lowercased()) }) {
                if let amount = decimalNumbers(in: line).max() {
                    return amount
                }
            }
        }
        // 找不到關鍵字時，退而求其次取全文中最大的金額（通常收據總額是最大的數字）
        let allText = lines.joined(separator: "\n")
        return decimalNumbers(in: allText).max()
    }

    private static func decimalNumbers(in text: String) -> [Decimal] {
        let pattern = #"[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        return matches.compactMap { match in
            let raw = nsText.substring(with: match.range).replacingOccurrences(of: ",", with: "")
            return Decimal(string: raw)
        }
    }

    private static func extractCurrencyCode(from text: String) -> String? {
        if text.contains("NT$") || text.contains("新台幣") { return "TWD" }
        if text.contains("¥") || text.contains("円") { return "JPY" }
        if text.contains("€") { return "EUR" }
        if text.contains("£") { return "GBP" }
        if text.contains("$") { return "USD" }
        if text.contains("元") { return "TWD" }
        return nil
    }
}
