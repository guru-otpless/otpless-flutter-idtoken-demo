import Flutter
import OtplessBM
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  // OTPLESS: hand Magic Link / OAuth redirects (otpless.<appid>://otpless)
  // back to the SDK so it can complete authentication.
  //
  // Apps without a SceneDelegate do the same in AppDelegate's
  // application(_:open:options:) — see README.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts where Otpless.shared.isOtplessDeeplink(url: context.url) {
      Task(priority: .userInitiated) {
        await Otpless.shared.handleDeeplink(context.url)
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
