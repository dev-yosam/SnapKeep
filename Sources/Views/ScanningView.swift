import SwiftUI

/// 拍照/選圖後顯示的處理畫面：本機執行 OCR，再交給裝置端 AI（或規則式備援）結構化欄位。
struct ScanningView: View {
    let image: UIImage
    let onComplete: (ReceiptDraft) -> Void
    let onCancel: () -> Void

    @State private var statusText = "正在辨識文字…"
    @State private var errorMessage: String?

    private let ocrService = OCRService()
    private let parsingService = ReceiptParsingService()

    var body: some View {
        VStack(spacing: 24) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 6)
                .padding(.top, 40)

            if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("返回") { onCancel() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("所有分析都在你的裝置上完成，不會上傳任何資料。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()

            if errorMessage == nil {
                Button("取消", role: .cancel) { onCancel() }
                    .padding(.bottom, 24)
            }
        }
        .task {
            await runPipeline()
        }
    }

    private func runPipeline() async {
        do {
            statusText = "正在辨識文字…"
            let ocrResult = try await ocrService.recognizeText(in: image)

            statusText = "正在分析收據內容…"
            let parsed = await parsingService.parse(ocrText: ocrResult.fullText)

            let draft = ReceiptDraft(image: image, parsed: parsed, rawOCRText: ocrResult.fullText)
            onComplete(draft)
        } catch {
            errorMessage = "無法辨識這張照片，請確認照片清晰後再試一次。\n(\(error.localizedDescription))"
        }
    }
}
