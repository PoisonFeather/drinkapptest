import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCxlfZ_j9P_M4Y1NAwXc1tY67Zpb-KHIU8") // ← cheia ta reală
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    WorkmanagerPlugin.register(with: self.registrar(forPlugin: "WorkmanagerPlugin")!)

  }
}
