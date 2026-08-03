import Foundation
import SwiftData

/// 單張收據的結構化資料。所有欄位皆儲存在裝置本機的 SwiftData（底層為 SQLite）資料庫中，
/// 不會有任何網路同步或雲端備份。
@Model
final class Receipt {
    /// 唯一識別碼
    @Attribute(.unique) var id: UUID

    /// 商家 / 店家名稱
    var merchantName: String

    /// 交易日期（若辨識不到則預設為建立當下的時間）
    var transactionDate: Date

    /// 總金額（以最小貨幣單位以外的十進位數字儲存，例如 123.45）
    var totalAmount: Decimal

    /// 貨幣代碼，例如 "TWD"、"USD"
    var currencyCode: String

    /// 稅額（可為 nil，代表未辨識到或不適用）
    var taxAmount: Decimal?

    /// 分類名稱（對應 ReceiptCategory.name，避免關聯刪除造成資料遺失，僅存名稱字串）
    var categoryName: String

    /// 使用者備註
    var note: String

    /// OCR 辨識出的原始文字，保留以便使用者日後校正或除錯
    var rawOCRText: String

    /// 收據影像相對檔名（實際檔案儲存在 App 的 Documents/ReceiptImages 目錄下）
    var imageFileName: String

    /// 這筆資料是否由 AI 結構化解析產生（false 代表使用者手動輸入或以規則式解析）
    var wasParsedByAI: Bool

    /// 建立時間
    var createdAt: Date

    /// 最後修改時間
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        merchantName: String,
        transactionDate: Date,
        totalAmount: Decimal,
        currencyCode: String = "TWD",
        taxAmount: Decimal? = nil,
        categoryName: String = "未分類",
        note: String = "",
        rawOCRText: String = "",
        imageFileName: String,
        wasParsedByAI: Bool,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.merchantName = merchantName
        self.transactionDate = transactionDate
        self.totalAmount = totalAmount
        self.currencyCode = currencyCode
        self.taxAmount = taxAmount
        self.categoryName = categoryName
        self.note = note
        self.rawOCRText = rawOCRText
        self.imageFileName = imageFileName
        self.wasParsedByAI = wasParsedByAI
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
