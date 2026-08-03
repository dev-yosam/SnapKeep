import Foundation
import Vision
import UIKit

/// 使用 Apple Vision 框架在裝置本機執行文字辨識（OCR）。
/// 完全離線運作，不會呼叫任何網路 API。
enum OCRServiceError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無法讀取影像內容。"
        case .recognitionFailed(let error):
            return "文字辨識失敗：\(error.localizedDescription)"
        }
    }
}

struct OCRLine {
    let text: String
    /// 於畫面上的正規化座標（0...1），左下角為原點，方便日後做版面分析
    let boundingBox: CGRect
}

struct OCRResult {
    let fullText: String
    let lines: [OCRLine]
}

final class OCRService {

    /// 針對收據照片做文字辨識，使用精確模式並支援繁體中文與英文語言校正。
    func recognizeText(in image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRServiceError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(fullText: "", lines: []))
                    return
                }

                var lines: [OCRLine] = []
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    lines.append(OCRLine(text: candidate.string, boundingBox: observation.boundingBox))
                }

                let fullText = lines.map(\.text).joined(separator: "\n")
                continuation.resume(returning: OCRResult(fullText: fullText, lines: lines))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en-US"]
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRServiceError.recognitionFailed(error))
            }
        }
    }
}

private extension UIImage {
    /// 將 UIImage.Orientation 轉為 Vision 所需的 CGImagePropertyOrientation
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
