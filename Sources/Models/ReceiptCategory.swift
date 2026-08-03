import Foundation
import SwiftData

/// 收據分類，可由使用者自訂新增／刪除／改色。
@Model
final class ReceiptCategory {
    @Attribute(.unique) var name: String

    /// 顯示用的 SF Symbol 名稱
    var symbolName: String

    /// 顯示用的顏色（以 hex 字串儲存，例如 "#FF9500"）
    var colorHex: String

    /// 是否為系統預設分類（預設分類不可被刪除，只能重新命名）
    var isDefault: Bool

    /// 排序權重，數字越小越前面
    var sortOrder: Int

    init(
        name: String,
        symbolName: String = "tag",
        colorHex: String = "#8E8E93",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    /// App 首次啟動時建立的預設分類
    static let defaultCategories: [ReceiptCategory] = [
        ReceiptCategory(name: "餐飲", symbolName: "fork.knife", colorHex: "#FF9500", isDefault: true, sortOrder: 0),
        ReceiptCategory(name: "交通", symbolName: "car.fill", colorHex: "#007AFF", isDefault: true, sortOrder: 1),
        ReceiptCategory(name: "日用品", symbolName: "cart.fill", colorHex: "#34C759", isDefault: true, sortOrder: 2),
        ReceiptCategory(name: "醫療", symbolName: "cross.case.fill", colorHex: "#FF3B30", isDefault: true, sortOrder: 3),
        ReceiptCategory(name: "娛樂", symbolName: "gamecontroller.fill", colorHex: "#AF52DE", isDefault: true, sortOrder: 4),
        ReceiptCategory(name: "辦公", symbolName: "briefcase.fill", colorHex: "#5AC8FA", isDefault: true, sortOrder: 5),
        ReceiptCategory(name: "未分類", symbolName: "tag", colorHex: "#8E8E93", isDefault: true, sortOrder: 99)
    ]
}
