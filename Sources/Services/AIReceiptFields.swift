import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// 交給 Apple Foundation Models（裝置端大型語言模型）產生的結構化欄位。
/// 使用 @Generable 讓模型直接輸出符合此結構的 JSON，不需要自己寫 JSON 解析與容錯邏輯。
@available(iOS 26.0, *)
@Generable
struct AIReceiptFields {
    @Guide(description: "收據上的商家或店家名稱；若完全無法辨識，請填「未知商家」")
    var merchantName: String

    @Guide(description: "交易日期，一律輸出成 yyyy-MM-dd 格式；若無法辨識，請留空字串")
    var transactionDate: String

    @Guide(description: "收據的總金額（含稅），只填數字，不含貨幣符號或千分位逗號")
    var totalAmount: Double

    @Guide(description: "稅額，只填數字；若收據上沒有列出稅額，請填 0")
    var taxAmount: Double

    @Guide(description: "三碼 ISO 貨幣代碼，例如 TWD、USD、JPY、EUR；若無法判斷，請填 TWD")
    var currencyCode: String

    @Guide(description: "從下列分類中選出最符合的一個：餐飲、交通、日用品、醫療、娛樂、辦公、未分類")
    var suggestedCategory: String
}
#endif
