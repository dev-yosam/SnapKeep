import XCTest
@testable import SnapKeep

final class RuleBasedReceiptParserTests: XCTestCase {

    private let parser = RuleBasedReceiptParser()

    func testExtractsTotalAmountFromKeywordLine() {
        let text = """
        全家便利商店
        飯糰 35
        茶葉蛋 15
        總計 50
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(50))
        XCTAssertFalse(result.usedAI)
    }

    func testGuessesMerchantNameFromFirstLine() {
        let text = """
        ABC 咖啡館
        拿鐵 120
        總計 120
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.merchantName, "ABC 咖啡館")
    }

    func testFallsBackToMaxAmountWhenNoKeywordFound() {
        let text = """
        某商店
        商品A 30
        商品B 88
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(88))
    }

    func testDefaultsToTWDWhenNoCurrencySymbolFound() {
        let text = "某商店\n總計 100"
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.currencyCode, "TWD")
    }

    func testDetectsUSDFromDollarSign() {
        let text = "Coffee Shop\nTotal $12.50"
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.currencyCode, "USD")
    }

    func testEmptyTextProducesZeroAmountAndUnknownMerchant() {
        let result = parser.parse(ocrText: "")
        XCTAssertEqual(result.totalAmount, Decimal(0))
        XCTAssertEqual(result.merchantName, "未知商家")
    }
}
