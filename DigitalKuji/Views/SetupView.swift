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
            VStack(spacing: 0) {
                Picker("モード", selection: $manager.mode) {
                    ForEach(KujiMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        switch manager.mode {
                        case .number: NumberSetupView(manager: manager)
                        case .color:  ColorSetupView(manager: manager)
                        case .text:   TextSetupView(manager: manager, newText: $newText)
                        }
                    }
                    .padding()
                }

                Button {
                    manager.setup()
                    navigate = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("開始する").fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStart ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .disabled(!canStart)
                .navigationDestination(isPresented: $navigate) {
                    DrawView(manager: manager)
                }
            }
            .navigationTitle("デジタルくじ引き")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 数字モード

struct NumberSetupView: View {
    @ObservedObject var manager: KujiManager

    var count: Int { max(0, manager.numberMax - manager.numberMin + 1) }

    var body: some View {
        VStack(spacing: 16) {
            GroupBox("範囲設定") {
                VStack(spacing: 12) {
                    HStack {
                        Text("最小")
                        Spacer()
                        Stepper("\(manager.numberMin)",
                                value: $manager.numberMin,
                                in: 1...99)
                    }
                    Divider()
                    HStack {
                        Text("最大")
                        Spacer()
                        Stepper("\(manager.numberMax)",
                                value: $manager.numberMax,
                                in: 2...100)
                    }
                }
                .padding(.vertical, 4)
            }

            if count > 0 {
                Text("\(count) 枚のくじが入ります")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if count <= 30 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(manager.numberMin...manager.numberMax, id: \.self) { n in
                            Text("\(n)")
                                .frame(width: 44, height: 44)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 色モード

struct ColorSetupView: View {
    @ObservedObject var manager: KujiManager

    let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使う色を選んでください")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(KujiColorOption.all) { option in
                    let selected = manager.selectedColorIDs.contains(option.id)
                    Button {
                        if selected {
                            manager.selectedColorIDs.remove(option.id)
                        } else {
                            manager.selectedColorIDs.insert(option.id)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        Circle().strokeBorder(
                                            selected ? Color.primary : Color.gray.opacity(0.3),
                                            lineWidth: selected ? 3 : 1
                                        )
                                    )
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(
                                            ["yellow", "cyan"].contains(option.id) ? .black : .white
                                        )
                                }
                            }
                            Text(option.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("\(manager.selectedColorIDs.count) 色選択中")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - テキストモード

struct TextSetupView: View {
    @ObservedObject var manager: KujiManager
    @Binding var newText: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("くじに入れる項目を追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                TextField("例: 田中、Aチーム...", text: $newText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onSubmit { addItem() }

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if manager.textItems.isEmpty {
                Text("まだ項目がありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(manager.textItems.indices, id: \.self) { i in
                        HStack {
                            Image(systemName: "ticket")
                                .foregroundColor(.red)
                            Text(manager.textItems[i])
                            Spacer()
                            Button {
                                manager.textItems.remove(at: i)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)

                        if i < manager.textItems.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Text("全 \(manager.textItems.count) 枚")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
