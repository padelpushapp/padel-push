import UIKit
import Flutter
import GoogleMaps   // ← IMPORTANTE

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GMSServices.provideAPIKey("AIzaSyDZBS_bZKMKB9Zw3HYOYQpawFdOQQYdLcM")  // ← AÑADE TU API KEY

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
