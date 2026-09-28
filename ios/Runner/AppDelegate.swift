import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let declination = DeclinationReader()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // الانحراف المغناطيسي لشاشة القبلة — نفس القناة على أندرويد (MainActivity.kt).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GrobiGeomagnetic") {
      let channel = FlutterMethodChannel(
        name: "com.misoor.grobi/geomagnetic", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "declination", let self = self else {
          result(FlutterMethodNotImplemented)
          return
        }
        self.declination.read(result)
      }
    }
  }
}

/// الانحراف المغناطيسي المحلي على iOS = الاتجاه الحقيقي − المغناطيسي من CLHeading
/// (يحسبه النظام من موقع الجهاز بلا إنترنت). يُعيد null إن لم يتوفّر خلال ٥ ثوانٍ.
final class DeclinationReader: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var pending: [FlutterResult] = []
  private var timer: Timer?

  override init() {
    super.init()
    manager.delegate = self
  }

  func read(_ result: @escaping FlutterResult) {
    guard CLLocationManager.headingAvailable() else {
      result(nil)
      return
    }
    pending.append(result)
    if pending.count > 1 { return }
    // الاتجاه الحقيقي يحتاج موقعاً، فنشغّل الاثنين معاً ثم نوقفهما فور أول قراءة.
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
    timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
      self?.finish(nil)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    // trueHeading سالب = لم يُحدَّد بعد (لا موقع).
    guard newHeading.trueHeading >= 0 else { return }
    var value = newHeading.trueHeading - newHeading.magneticHeading
    if value > 180 { value -= 360 }
    if value < -180 { value += 360 }
    finish(value)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finish(nil)
  }

  private func finish(_ value: Double?) {
    timer?.invalidate()
    timer = nil
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
    let callbacks = pending
    pending = []
    for callback in callbacks {
      callback(value)
    }
  }
}
