//
//  NTKModelManager.swift
//  SpeedAndDirection
//
//  Created by MK on 2018/11/08.
//  Copyright © 2018 NotenkiApps. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation

enum NTKModelManagerLocationStatus {
  case locationUpdateStarting
  case locationUpdateStopping
  case locationUpdateError
}

enum NTKModelManagerSpeechSpeedStatus {
  case speechSpeedStarting
  case speechSpeedStopping
}

enum NTKModelManagerSpeechDirectionStatus {
  case speechDirectionStarting
  case speechDirectionStopping
}

class NTKModelManager: NSObject, CLLocationManagerDelegate, AVSpeechSynthesizerDelegate {
  // MARK: -- パブリックプロパティ --
  let NTKDataManagerDidUpdateLocation = Notification.Name("NTKDataManagerDidUpdateLocation")
  let NTKDataManagerDidFailWithError = Notification.Name("NTKDataManagerDidFailWithError")

  // MARK: -- プライベートプロパティ --
  private let _center = NotificationCenter.default
  private var _locationManager: CLLocationManager!
  private var _speechSynthesizer: AVSpeechSynthesizer!
  private var _locationStatus: NTKModelManagerLocationStatus! = .locationUpdateStopping
  private var _speechSpeedStatus: NTKModelManagerSpeechSpeedStatus! = .speechSpeedStopping
  private var _speechDirectionStatus: NTKModelManagerSpeechDirectionStatus! = .speechDirectionStopping

  //--------------------------------------------------------------//
  // MARK: -- 初期化 --
  //--------------------------------------------------------------//
  // シングルトン
  class var sharedInstance: NTKModelManager {
    struct Static {
      static let instance: NTKModelManager = NTKModelManager()
    }
    return Static.instance
  }
  
  private override init() {
    super.init()

    // ロケーションマネージャーを生成する
    _locationManager = CLLocationManager()
    _locationManager.delegate = self
    _locationManager.requestAlwaysAuthorization()
    _locationManager.distanceFilter = kCLDistanceFilterNone
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest
    _locationManager.headingFilter = kCLHeadingFilterNone
    _locationManager.headingOrientation = CLDeviceOrientation.portrait

    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      // Request when-in-use authorization initially
      _locationManager.requestWhenInUseAuthorization()
      break
      
    case .restricted, .denied:
      // Disable location features
//      disableMyLocationBasedFeatures()
      break
      
    case .authorizedWhenInUse, .authorizedAlways:
      // Enable location features
//      enableMyWhenInUseFeatures()
      break
    @unknown default:
      fatalError()
    }

    // スピーチシンセサイザーを生成する
    _speechSynthesizer = AVSpeechSynthesizer()
  }

  //--------------------------------------------------------------//
  // MARK: -- パブリックインスタンスメソッド --
  //--------------------------------------------------------------//
  func start() {
    _locationManager.startUpdatingLocation()
    _locationManager.startUpdatingHeading()
  }

  func stop() {
    _locationManager.stopUpdatingLocation()
    _locationManager.stopUpdatingHeading()
  }

  func startSpeekSpeed() {
    _speechSpeedStatus = .speechSpeedStarting
  }
  
  func stopSpeekSpeed() {
    _speechSpeedStatus = .speechSpeedStopping
  }
  
  func startSpeekDirection() {
    _speechDirectionStatus = .speechDirectionStarting
  }
  
  func stopSpeekDirection() {
    _speechDirectionStatus = .speechDirectionStopping
  }
  
  //--------------------------------------------------------------//
  // MARK: -- CLLocationManagerDelegate --
  //--------------------------------------------------------------//
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // locationが入ってない場合は終了する
    if locations.count <= 0 {
      return
    }
    
    // 速度と方角を取得する
    let currentLocation = locations[0]
    let currentSpd = round(currentLocation.speed * 10) / 10 // XX.X m/s
    let currentSpeed = String(format: "%.1f", currentSpd)
    let dict:[String:String] = ["currentSpeed": currentSpeed]

    // ModelManagerの状態を更新する
    _locationStatus = .locationUpdateStarting

    // ViewControllerにデータ更新を通知する
    _center.post(name: NTKDataManagerDidUpdateLocation,
                 object: self,
                 userInfo: dict)
    
    // スピーチする
    _speechSpeedAndDirection(currentSpeedNew: dict["currentSpeed"])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // 通知データを生成する
//    let dict:[String:Error] = ["error": error]
    let dict:[String:String] = ["currentSpeed": "ERR"]

    // ModelManagerの状態を更新する
    _locationStatus = .locationUpdateError

    // ViewControllerにデータ更新を通知する
//    _center.post(name: NTKDataManagerDidUpdateLocation,
    _center.post(name: NTKDataManagerDidUpdateLocation,
                 object: self,
                 userInfo: dict)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    // 方角を取得する
    let currentDir = Int(round(newHeading.trueHeading)) // course/360 degree
    let currentDirection = String(format: "%03d", currentDir)
    let dict:[String:String] = ["currentDirection": currentDirection]
//    print("currentDirection[\(currentDirection)] \(newHeading.timestamp)");

    // ViewControllerにデータ更新を通知する
    _center.post(name: NTKDataManagerDidUpdateLocation,
                 object: self,
                 userInfo: dict)

    // スピーチする
    _speechSpeedAndDirection(currentDirectionNew: dict["currentDirection"])
  }
  
  //--------------------------------------------------------------//
  // MARK: -- AVSpeechSynthesizerDelegate --
  //--------------------------------------------------------------//

  //--------------------------------------------------------------//
  // MARK: -- プライベートメソッド --
  //--------------------------------------------------------------//
  private func _speechSpeedAndDirection(currentSpeedNew: String? = nil, currentDirectionNew: String? = nil) {
    struct Static {
      static var currentSpeed:String = ""
      static var currentDirection:String = ""
    }

    // 引数speed、directionが存在する場合は、static変数に格納する
    if let speed = currentSpeedNew {
      Static.currentSpeed = speed
    }
    if let direction = currentDirectionNew {
      Static.currentDirection = direction
    }

    // speech中でなければspeechする
    if !_speechSynthesizer.isSpeaking {
      var speechString: String = ""
      
      // スピーチ文字列を生成する
      if _speechSpeedStatus == NTKModelManagerSpeechSpeedStatus.speechSpeedStarting &&
        !Static.currentSpeed.isEmpty {
        speechString += "秒速" + Static.currentSpeed + "メートル　"
      }
      if _speechDirectionStatus == NTKModelManagerSpeechDirectionStatus.speechDirectionStarting &&
        !Static.currentDirection.isEmpty {
        speechString += "方角" + Static.currentDirection + "ど　"
      }

      // スピーチを実行する
      if !speechString.isEmpty {
        let speechUtterance = AVSpeechUtterance(string: speechString)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        _speechSynthesizer.speak(speechUtterance)
      }
    }
  }
}
