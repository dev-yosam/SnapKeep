import Foundation

enum DateParsing {

    /// 嘗試以多種常見格式解析日期字串（例如 AI 回傳的 "2026-01-05" 或 OCR 常見格式）。
    static func parseFlexibleDate(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formats = [
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yyyy.MM.dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy年MM月dd日"
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        if let isoDate = ISO8601DateFormatter().date(from: trimmed) {
            return isoDate
        }

        return nil
    }

    /// 使用 NSDataDetector 從一大段文字中偵測第一個日期（用於規則式備援解析）。
    static func firstDetectedDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).first?.date
    }
}
