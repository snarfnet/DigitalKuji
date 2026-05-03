import SwiftUI

struct ContentView: View {
    @StateObject private var manager = KujiManager()

    var body: some View {
        SetupView(manager: manager)
    }
}
