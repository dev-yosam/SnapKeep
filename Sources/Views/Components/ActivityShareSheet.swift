import SwiftUI
import UIKit

/// 包裝系統分享面板，讓使用者自行決定匯出的檔案要傳到哪裡（App 本身不會主動上傳）。
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
