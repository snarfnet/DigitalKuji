import Foundation
import SwiftUI

enum KujiMode: String, CaseIterable, Identifiable {
    case number = "数字"
    case color = "色"
    case text = "テキスト"
    var id: String { rawValue }
}

struct KujiColorOption: Identifiable, Equatable {
    let id: String
    let name: String
    let color: Color

    static let all: [KujiColorOption] = [
        .init(id: "red",    name: "赤",    color: .red),
        .init(id: "blue",   name: "青",    color: .blue),
        .init(id: "yellow", name: "黄",    color: Color(hue: 0.13, saturation: 1, brightness: 1)),
        .init(id: "green",  name: "緑",    color: .green),
        .init(id: "purple", name: "紫",    color: .purple),
        .init(id: "orange", name: "橙",    color: .orange),
        .init(id: "pink",   name: "ピンク", color: .pink),
        .init(id: "cyan",   name: "水色",  color: .cyan),
        .init(id: "brown",  name: "茶色",  color: .brown),
        .init(id: "black",  name: "黒",    color: Color(white: 0.15)),
    ]
}

class KujiManager: ObservableObject {
    @Published var mode: KujiMode = .number
    @Published var numberMin: Int = 1
    @Published var numberMax: Int = 10
    @Published var selectedColorIDs: Set<String> = ["red", "blue", "yellow", "green"]
    @Published var textItems: [String] = []
    @Published var pool: [String] = []
    @Published var drawn: [String] = []
    @Published var isConfigured: Bool = false

    func colorForName(_ name: String) -> Color {
        KujiColorOption.all.first { $0.name == name }?.color ?? .gray
    }

    func colorIDForName(_ name: String) -> String? {
        KujiColorOption.all.first { $0.name == name }?.id
    }

    func setup() {
        var items: [String] = []
        switch mode {
        case .number:
            let lo = min(numberMin, numberMax)
            let hi = max(numberMin, numberMax)
            items = (lo...hi).map { "\($0)" }
        case .color:
            items = KujiColorOption.all
                .filter { selectedColorIDs.contains($0.id) }
                .map { $0.name }
        case .text:
            items = textItems.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        guard !items.isEmpty else { return }
        pool = items.shuffled()
        drawn = []
        isConfigured = true
    }

    func draw() -> String? {
        guard !pool.isEmpty else { return nil }
        let item = pool.removeFirst()
        drawn.insert(item, at: 0)
        return item
    }

    func reset() {
        pool = (pool + drawn).shuffled()
        drawn = []
    }

    var isEmpty: Bool { pool.isEmpty }
    var totalCount: Int { pool.count + drawn.count }
    var remainingCount: Int { pool.count }
}
