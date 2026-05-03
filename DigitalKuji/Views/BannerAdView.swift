import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    // TODO: AdMobコンソールで本番IDに差し替え
    // テスト用: ca-app-pub-3940256099942544/2934735716
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let width = UIScreen.main.bounds.width
        let adSize = currentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
