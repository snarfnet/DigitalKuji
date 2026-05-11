import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        guard uiView.rootViewController == nil else { return }
        if let rootVC = uiView.window?.rootViewController {
            uiView.rootViewController = rootVC
            uiView.load(GADRequest())
        }
    }
}
