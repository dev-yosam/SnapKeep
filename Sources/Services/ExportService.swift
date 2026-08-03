import Foundation

/// 將收據資料匯出成 CSV，純本機檔案操作，供使用者透過系統分享面板自行決定要存到哪裡
/// （例如 AirDrop、檔案 App、或傳送給自己），App 本身不會主動上傳任何資料。
enum ExportService {

    static func makeCSV(from receipts: [Receipt]) -> String {
        var rows = ["日期,商家,分類,金額,幣別,稅額,備註"]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for receipt in receipts.sorted(by: { $0.transactionDate < $1.transactionDate }) {
            let date = dateFormatter.string(from: receipt.transactionDate)
            let merchant = csvEscape(receipt.merchantName)
            let category = csvEscape(receipt.categoryName)
            let amount = "\(receipt.totalAmount)"
            let currency = receipt.currencyCode
            let tax = receipt.taxAmount.map { "\($0)" } ?? ""
            let note = csvEscape(receipt.note)
            rows.append("\(date),\(merchant),\(category),\(amount),\(currency),\(tax),\(note)")
        }

        return rows.joined(separator: "\n")
    }

    /// 將 CSV 字串寫到暫存目錄，回傳可供分享的檔案 URL。
    static func writeTemporaryCSVFile(csv: String) throws -> URL {
        let fileName = "SnapKeep-Export-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
