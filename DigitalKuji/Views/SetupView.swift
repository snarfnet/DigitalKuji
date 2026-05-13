import SwiftUI

struct SetupView: View {
    @ObservedObject var manager: KujiManager
    @State private var newText: String = ""
    @State private var navigate = false

    var canStart: Bool {
        switch manager.mode {
        case .number: return manager.numberMax >= manager.numberMin
        case .color:  return !manager.selectedColorIDs.isEmpty
        case .text:   return !manager.textItems.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OmikujiScreenBackground()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            header
                            modeSelector

                            switch manager.mode {
                            case .number: NumberSetupView(manager: manager)
                            case .color:  ColorSetupView(manager: manager)
                            case .text:   TextSetupView(manager: manager, newText: $newText)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 110)
                    }

                    startButton
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigate) {
                DrawView(manager: manager)
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(KujiTheme.goldGradient)
                Text("DIGITAL KUJI")
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(KujiTheme.mutedInk)
            }

            Text("デジタルくじ引き")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(KujiTheme.ink)

            Text("数字・色・テキストから、今すぐ抽選。")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KujiTheme.mutedInk)
        }
        .padding(.top, 6)
    }

    var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(KujiMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        manager.mode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: mode))
                            .font(.system(size: 13, weight: .bold))
                        Text(mode.rawValue)
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(manager.mode == mode ? Color.white : KujiTheme.ink)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(manager.mode == mode ? KujiTheme.vermilion : Color.white.opacity(0.58))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(manager.mode == mode ? KujiTheme.gold.opacity(0.75) : KujiTheme.paperLine.opacity(0.45), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    var startButton: some View {
        Button {
            manager.setup()
            navigate = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "seal.fill")
                Text("くじをはじめる")
                    .fontWeight(.heavy)
            }
            .font(.system(size: 18, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canStart ? KujiTheme.cardGradient : LinearGradient(colors: [.gray.opacity(0.55), .gray.opacity(0.45)], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: KujiTheme.deepRed.opacity(canStart ? 0.26 : 0), radius: 16, y: 8)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .disabled(!canStart)
    }

    func icon(for mode: KujiMode) -> String {
        switch mode {
        case .number: return "number.circle.fill"
        case .color: return "paintpalette.fill"
        case .text: return "textformat"
        }
    }
}

struct NumberSetupView: View {
    @ObservedObject var manager: KujiManager

    var count: Int { max(0, manager.numberMax - manager.numberMin + 1) }

    var body: some View {
        PaperPanel {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(icon: "slider.horizontal.3", title: "範囲設定", caption: "\(count) 枚のくじ")

                VStack(spacing: 12) {
                    numberRow(title: "最小", value: $manager.numberMin, range: 1...99)
                    Divider().overlay(KujiTheme.paperLine.opacity(0.5))
                    numberRow(title: "最大", value: $manager.numberMax, range: 2...100)
                }

                if count > 0 && count <= 30 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(manager.numberMin...manager.numberMax, id: \.self) { n in
                            KujiTicketLabel(text: "\(n)")
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    func numberRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(KujiTheme.ink)
            Spacer()
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(KujiTheme.vermilion)
                    .frame(minWidth: 42)
            }
            .tint(KujiTheme.vermilion)
        }
    }
}

struct ColorSetupView: View {
    @ObservedObject var manager: KujiManager

    let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        PaperPanel {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(icon: "paintpalette.fill", title: "色を選ぶ", caption: "\(manager.selectedColorIDs.count) 色選択中")

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(KujiColorOption.all) { option in
                        let selected = manager.selectedColorIDs.contains(option.id)
                        Button {
                            if selected {
                                manager.selectedColorIDs.remove(option.id)
                            } else {
                                manager.selectedColorIDs.insert(option.id)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 58, height: 58)
                                        .shadow(color: option.color.opacity(0.28), radius: 8, y: 4)
                                        .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 2))
                                        .overlay(Circle().stroke(selected ? KujiTheme.gold : Color.clear, lineWidth: 4))
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .heavy))
                                            .foregroundColor(["yellow", "cyan"].contains(option.id) ? .black : .white)
                                    }
                                }
                                Text(option.name)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(KujiTheme.ink)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct TextSetupView: View {
    @ObservedObject var manager: KujiManager
    @Binding var newText: String
    @FocusState private var focused: Bool

    var body: some View {
        PaperPanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(icon: "textformat", title: "項目を入れる", caption: "自由なくじを作成")

                HStack(spacing: 10) {
                    TextField("例: Aチーム", text: $newText)
                        .textFieldStyle(.plain)
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(KujiTheme.paperLine.opacity(0.5), lineWidth: 1)
                        )
                        .focused($focused)
                        .onSubmit { addItem() }

                    Button(action: addItem) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(KujiTheme.vermilion, in: Circle())
                    }
                    .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if manager.textItems.isEmpty {
                    Text("まだ項目がありません")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KujiTheme.mutedInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    VStack(spacing: 8) {
                        ForEach(manager.textItems.indices, id: \.self) { i in
                            HStack {
                                Image(systemName: "ticket.fill")
                                    .foregroundStyle(KujiTheme.gold)
                                Text(manager.textItems[i])
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(KujiTheme.ink)
                                Spacer()
                                Button {
                                    manager.textItems.remove(at: i)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(KujiTheme.vermilion.opacity(0.78))
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    func addItem() {
        let trimmed = newText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        manager.textItems.append(trimmed)
        newText = ""
    }
}

struct SectionTitle: View {
    let icon: String
    let title: String
    let caption: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.heavy))
                .foregroundStyle(KujiTheme.ink)
            Spacer()
            Text(caption)
                .font(.caption.weight(.bold))
                .foregroundStyle(KujiTheme.mutedInk)
        }
    }
}

struct KujiTicketLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, design: .rounded).weight(.heavy))
            .foregroundStyle(KujiTheme.vermilion)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(KujiTheme.paper.opacity(0.88), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(KujiTheme.gold.opacity(0.38), lineWidth: 1)
            )
    }
}
