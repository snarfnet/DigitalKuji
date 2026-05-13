import SwiftUI

private let bannerAdUnitID = "ca-app-pub-9404799280370656/3701617069"

struct DrawView: View {
    @ObservedObject var manager: KujiManager

    @State private var displayText: String = "?"
    @State private var isAnimating: Bool = false
    @State private var hasDrawn: Bool = false
    @State private var cardScale: Double = 1.0

    var body: some View {
        ZStack {
            OmikujiScreenBackground()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        statusPanel
                        drawCard
                        shakeHint
                        historySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }

                BannerAdView(adUnitID: bannerAdUnitID)
                    .frame(height: 50)
                    .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("抽選")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onShake { performDraw() }
    }

    var statusPanel: some View {
        PaperPanel {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("残り \(manager.remainingCount) 枚")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(KujiTheme.ink)
                    Text("全 \(manager.totalCount) 枚から抽選中")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KujiTheme.mutedInk)
                }

                Spacer()

                ProgressRing(progress: manager.totalCount == 0 ? 0 : Double(manager.drawn.count) / Double(manager.totalCount))
                    .frame(width: 56, height: 56)

                Button {
                    manager.reset()
                    displayText = "?"
                    hasDrawn = false
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(KujiTheme.vermilion)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.7), in: Circle())
                }
                .disabled(isAnimating)
            }
        }
    }

    var drawCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .frame(height: 330)
                .offset(y: 14)
                .blur(radius: 18)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(cardGradient)
                .frame(height: 330)
                .overlay(cardPattern)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(KujiTheme.gold.opacity(0.70), lineWidth: 1.5)
                )

            cardContent
        }
        .scaleEffect(cardScale)
        .padding(.top, 4)
    }

    var cardPattern: some View {
        ZStack {
            Circle()
                .stroke(KujiTheme.gold.opacity(0.26), lineWidth: 2)
                .frame(width: 180, height: 180)
                .offset(x: -120, y: -90)
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 24)
                .frame(width: 250, height: 250)
                .offset(x: 130, y: 110)
            VStack {
                Spacer()
                Rectangle()
                    .fill(KujiTheme.gold.opacity(0.22))
                    .frame(height: 1)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 26)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    }

    var cardGradient: LinearGradient {
        manager.isEmpty
        ? LinearGradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)
        : KujiTheme.cardGradient
    }

    @ViewBuilder
    var cardContent: some View {
        if manager.isEmpty && !isAnimating {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(KujiTheme.goldGradient)
                Text("全部引いた！")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)
                Text("リセットしてもう一度")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        } else if hasDrawn || isAnimating {
            VStack(spacing: 14) {
                if manager.mode == .color && hasDrawn && !isAnimating {
                    Circle()
                        .fill(manager.colorForName(displayText))
                        .frame(width: 80, height: 80)
                        .overlay(Circle().strokeBorder(.white.opacity(0.65), lineWidth: 3))
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                }
                Text(displayText)
                    .font(.system(size: fontSize(for: displayText), weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
                    .minimumScaleFactor(0.28)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        } else {
            VStack(spacing: 14) {
                Image(systemName: "questionmark.seal.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(KujiTheme.goldGradient)
                Text("振ってね")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    var shakeHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.title3)
                .foregroundStyle(KujiTheme.vermilion)
            Text(isAnimating ? "引いています..." : "端末を振ってくじを引こう")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KujiTheme.ink)
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(KujiTheme.paperLine.opacity(0.45), lineWidth: 1)
        )
    }

    @ViewBuilder
    var historySection: some View {
        if !manager.drawn.isEmpty {
            PaperPanel {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("履歴")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(KujiTheme.ink)
                        Spacer()
                        Text("\(manager.drawn.count) 枚引いた")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KujiTheme.mutedInk)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(manager.drawn.indices, id: \.self) { i in
                                historyChip(manager.drawn[i], isLatest: i == 0)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func historyChip(_ item: String, isLatest: Bool) -> some View {
        let size: CGFloat = isLatest ? 56 : 44

        if manager.mode == .color {
            Circle()
                .fill(manager.colorForName(item))
                .frame(width: size, height: size)
                .overlay(Circle().stroke(isLatest ? KujiTheme.gold : Color.white.opacity(0.7), lineWidth: isLatest ? 3 : 1.5))
        } else {
            Text(item)
                .font(.system(size: isLatest ? 16 : 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isLatest ? .white : KujiTheme.ink)
                .frame(minWidth: size, minHeight: size)
                .padding(.horizontal, 8)
                .background(isLatest ? KujiTheme.vermilion : KujiTheme.paper.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isLatest ? KujiTheme.gold.opacity(0.7) : KujiTheme.paperLine.opacity(0.55), lineWidth: 1)
                )
        }
    }

    func fontSize(for text: String) -> CGFloat {
        switch text.count {
        case ...2:  return 96
        case 3...4: return 68
        case 5...6: return 52
        default:    return 38
        }
    }

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
                    cardScale = 1.08
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

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(KujiTheme.paperLine.opacity(0.35), lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(KujiTheme.goldGradient, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(KujiTheme.ink)
        }
    }
}
