import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.merchantName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(receipt.categoryName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())

                    Text(Self.dateFormatter.string(from: receipt.transactionDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(CurrencyFormatter.format(amount: receipt.totalAmount, currencyCode: receipt.currencyCode))
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        Group {
            if let image = ImageStorageService().loadImage(fileName: receipt.imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .overlay(Image(systemName: "receipt").foregroundStyle(.secondary))
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
