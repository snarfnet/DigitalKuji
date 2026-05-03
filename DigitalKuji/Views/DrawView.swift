import SwiftUI

// TODO: AdMobコンソールで本番IDに差し替え
private let bannerAdUnitID = "ca-app-pub-9404799280370656/3701617069"

struct DrawView: View {
    @ObservedObject var manager: KujiManager

    @State private var displayText: String = "?"
    @State private var isAnimating: Bool = false
    @State private var hasDrawn: Bool = false
    @State private var cardScale: Double = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // ステータスバー
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("残り \(manager.remainingCount) 枚")
                        .font(.title3).bold()
                    Text("全 \(manager.totalCount) 枚")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if manager.totalCount > 0 {
                    ProgressView(
                        value: Double(manager.drawn.count),
                        total: Double(manager.totalCount)
                    )
                    .tint(.red)
                    .frame(width: 80)
                }
                Spacer()
                Button("リセット") {
                    manager.reset()
                    displayText = "?"
                    hasDrawn = false
                }
                .foregroundColor(.red)
                .disabled(isAnimating)
            }
            .padding()

            Spacer()

            // メインカード
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .offset(y: 8)
                    .blur(radius: 10)

                RoundedRectangle(cornerRadius: 24)
                    .fill(cardGradient)
                    .frame(width: 280, height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
                    )

                cardContent
            }
            .scaleEffect(cardScale)

            Spacer()

            // ヒント
            if !manager.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(isAnimating ? "引いています..." : "振ってくじを引こう！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }

            // 履歴
            historySection

            // バナー広告
            BannerAdView(adUnitID: bannerAdUnitID)
                .frame(height: 50)
        }
        .navigationTitle("デジタルくじ引き")
        .navigationBarTitleDisplayMode(.inline)
        .onShake { performDraw() }
    }

    // MARK: - カードグラデーション

    var cardGradient: LinearGradient {
        if manager.isEmpty {
            return LinearGradient(
                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.12, blue: 0.12),
                Color(red: 0.58, green: 0.04, blue: 0.04)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - カード内容

    @ViewBuilder
    var cardContent: some View {
        if manager.isEmpty && !isAnimating {
            // 全部引き終わり
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.white)
                Text("全部引いた！")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                Text("リセットしてもう一度")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        } else if hasDrawn || isAnimating {
            VStack(spacing: 10) {
                // 色モードの場合は色丸を表示
                if manager.mode == .color && hasDrawn && !isAnimating {
                    Circle()
                        .fill(manager.colorForName(displayText))
                        .frame(width: 72, height: 72)
                        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 2))
                        .shadow(radius: 4)
                }
                Text(displayText)
                    .font(.system(size: fontSize(for: displayText), weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .minimumScaleFactor(0.3)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        } else {
            // 待機中
            VStack(spacing: 10) {
                Image(systemName: "questionmark")
                    .font(.system(size: 72, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.85))
                Text("振ってね")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - 履歴

    @ViewBuilder
    var historySection: some View {
        if !manager.drawn.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("履歴")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("\(manager.drawn.count) 枚引いた")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(manager.drawn.indices, id: \.self) { i in
                            historyChip(manager.drawn[i], isLatest: i == 0)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
            .background(Color(.systemGray6))
        }
    }

    @ViewBuilder
    func historyChip(_ item: String, isLatest: Bool) -> some View {
        let size: CGFloat = isLatest ? 52 : 40

        if manager.mode == .color {
            Circle()
                .fill(manager.colorForName(item))
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(isLatest ? Color.red : Color.clear, lineWidth: 2)
                )
        } else {
            Text(item)
                .font(.system(size: isLatest ? 15 : 12, weight: .semibold, design: .rounded))
                .foregroundColor(isLatest ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minWidth: size, minHeight: size)
                .background(isLatest ? Color.red : Color(.systemGray5))
                .cornerRadius(10)
        }
    }

    // MARK: - ヘルパー

    func fontSize(for text: String) -> CGFloat {
        switch text.count {
        case ...2:  return 90
        case 3...4: return 64
        case 5...6: return 48
        default:    return 34
        }
    }

    // MARK: - 抽選

    func performDraw() {
        guard !manager.isEmpty && !isAnimating else { return }

        isAnimating = true
        hasDrawn = true

        let allItems = manager.pool + manager.drawn
        var cycleCount = 0

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        func nextCycle() {
            guard cycleCount < 15 else {
                let result = manager.draw() ?? "?"
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    displayText = result
                    cardScale = 1.12
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring()) {
                        cardScale = 1.0
                        isAnimating = false
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                return
            }

            displayText = allItems.randomElement() ?? "?"
            cycleCount += 1

            let delay = 0.055 + Double(cycleCount) * 0.012
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                nextCycle()
            }
        }

        nextCycle()
    }
}
