import Foundation
import UIKit

enum ImageStorageError: LocalizedError {
    case encodingFailed
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "無法將影像轉換成檔案格式。"
        case .fileNotFound: return "找不到對應的收據影像檔案。"
        }
    }
}

/// 將收據照片以 JPEG 格式儲存到 App 的 Documents 目錄下，完全存在裝置本機，
/// 不會上傳到 iCloud 或任何第三方伺服器（Documents 目錄本身也未啟用 iCloud 同步）。
final class ImageStorageService {

    private let fileManager = FileManager.default

    private var receiptImagesDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documents.appendingPathComponent("ReceiptImages", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    /// 儲存影像並回傳檔名（不含路徑），這個檔名會存進 SwiftData 的 Receipt.imageFileName。
    @discardableResult
    func saveImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw ImageStorageError.encodingFailed
        }
        let fileName = "\(UUID().uuidString).jpg"
        let url = receiptImagesDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return fileName
    }

    func loadImage(fileName: String) -> UIImage? {
        let url = receiptImagesDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(fileName: String) {
        let url = receiptImagesDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: url)
    }
}
