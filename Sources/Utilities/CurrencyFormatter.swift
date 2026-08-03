import Foundation

enum CurrencyFormatter {

    /// 依貨幣代碼格式化金額字串，例如 "NT$1,234"、"$12.50"
    static func format(amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = localeForCurrency(currencyCode)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyCode) \(amount)"
    }

    private static func localeForCurrency(_ currencyCode: String) -> Locale {
        switch currencyCode.uppercased() {
        case "TWD": return Locale(identifier: "zh_TW")
        case "USD": return Locale(identifier: "en_US")
        case "JPY": return Locale(identifier: "ja_JP")
        case "EUR": return Locale(identifier: "en_IE")
        case "CNY": return Locale(identifier: "zh_CN")
        default: return Locale.current
        }
    }
}
