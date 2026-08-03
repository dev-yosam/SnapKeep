import SwiftUI
import SwiftData

@main
struct SnapKeepApp: App {

    let modelContainer: ModelContainer = {
        let schema = Schema([Receipt.self, ReceiptCategory.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("無法建立本機資料庫：\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
