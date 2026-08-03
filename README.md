# SnapKeep（快拍收據夾）

一個 100% 離線的 iOS 收據管理 App：拍照 → 本機文字辨識（OCR）→ 裝置端 AI 結構化 → 存在手機本機資料庫。

沒有帳號、沒有雲端同步、沒有訂閱制，也沒有任何後端伺服器或 API 呼叫。

## 核心特色

- **拍照即完成**：拍下收據或從相簿選取，App 會自動辨識商家、日期、金額、稅額並建議分類。
- **完全離線 / 本機優先**：
  - 文字辨識使用 Apple 內建的 **Vision** 框架（`VNRecognizeTextRequest`），在裝置上執行。
  - 結構化解析優先使用 **Apple Foundation Models**（Apple Intelligence 裝置端大型語言模型，iOS 26+ 且需支援 Apple Intelligence 的機型）。
  - 當裝置不支援裝置端 AI 時，會自動退回到內建的規則式解析器（關鍵字 + 正規表示式 + 日期偵測），確保任何裝置都能使用。
  - 所有資料透過 **SwiftData**（底層即為本機 SQLite）儲存在 App 的 Documents 目錄，且明確停用 CloudKit 同步。
- **沒有網路請求**：整個 App 沒有任何 URLSession / API 呼叫，你可以直接檢查程式碼確認。
- **一次性、可攜的匯出**：可將收據匯出成 CSV，透過系統分享面板自行決定要存到哪裡（例如「檔案」App 或 AirDrop），App 本身不會主動上傳。

## 專案結構

```
SnapKeep/
├── project.yml                  # XcodeGen 專案設定（用來產生 .xcodeproj）
├── Sources/
│   ├── App/                     # App 進入點、Info.plist、entitlements
│   ├── Models/                  # SwiftData 資料模型（Receipt、ReceiptCategory）
│   ├── Services/                # OCR、AI 解析、規則式解析、圖片儲存、CSV 匯出
│   ├── Utilities/                # 日期解析、貨幣格式化
│   └── Views/                   # SwiftUI 畫面（列表、詳情、編輯、拍照流程、儀表板、設定）
├── Resources/
│   └── Assets.xcassets/         # App 圖示、強調色
└── Tests/
    └── SnapKeepTests/           # 解析邏輯的單元測試
```

## 在 Mac 上建置（必要條件）

原生 iOS App（SwiftUI + Vision + Foundation Models）**只能在 macOS 上使用 Xcode 建置與執行**，無法在 Windows 上編譯或跑模擬器。以下步驟請在 Mac 上進行：

### 1. 安裝需要的工具

- **Xcode 26 或以上**（透過 App Store 安裝），才會包含 Apple Intelligence 的 `FoundationModels` 框架 SDK。
- **XcodeGen**（用來把 `project.yml` 轉成 `.xcodeproj`，不需要手動維護 Xcode 專案檔）：

  ```bash
  brew install xcodegen
  ```

### 2. 產生並開啟 Xcode 專案

把整個 `SnapKeep` 資料夾複製到你的 Mac 上（例如透過 git clone、AirDrop 或雲端硬碟），然後在資料夾內執行：

```bash
cd SnapKeep
xcodegen generate
open SnapKeep.xcodeproj
```

### 3. 設定簽章

在 Xcode 專案設定的「Signing & Capabilities」頁籤，選擇你自己的 Apple ID / Team 進行簽章（個人開發用免費帳號即可在自己的裝置上測試）。

### 4. 執行

- **模擬器**：可以直接執行，但 iOS 模擬器不支援相機，也不支援 Apple Intelligence 推論，適合先確認畫面與流程（可用「從相簿選擇」路徑測試）。
- **實機**：建議用實體 iPhone 測試完整體驗（拍照 + 裝置端 AI）。若要用到 Foundation Models 的 AI 結構化功能，裝置需要：
  - 支援 Apple Intelligence 的機型（例如 iPhone 15 Pro 以上或更新機種）
  - 系統版本 iOS 26 以上
  - 在「設定 > Apple Intelligence 與 Siri」中已開啟 Apple Intelligence

  即使裝置不支援，App 仍會用內建規則式解析正常運作，只是準確度較低。

### 5. 執行測試

在 Xcode 中按 `Cmd + U`，或使用命令列：

```bash
xcodebuild test -scheme SnapKeep -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 隱私設計原則

- 沒有帳號系統、沒有登入頁面。
- 沒有任何分析 SDK、廣告 SDK 或第三方追蹤。
- 相機/相簿權限說明文字已明確告知使用者「所有處理均在本機完成」。
- `ModelConfiguration` 明確設定 `cloudKitDatabase: .none`，避免 SwiftData 意外開啟 iCloud 同步。
- 匯出功能一律透過系統分享面板，由使用者主動決定資料去向。

## 後續可以擴充的方向

- 收據多幣別統計與月度趨勢圖表
- 批次拍照 / 連續掃描模式
- 以 Face ID / Touch ID 鎖定 App
- iPad 版面優化、Widget、Shortcuts 整合
