//
//  NTKModelSpeedAndDirection.swift
//  SpeedAndDirection
//
//  Created by MK on 2019/09/01.
//  Copyright © 2019 NotenkiApps. All rights reserved.
//

import Foundation
import CoreLocation

class NTKModelSpeedAndDirection: NSObject {
  // MARK: -- パブリックプロパティ --
  public let speechStrings: String

  // MARK: -- プライベートプロパティ --
  private var _currentSpeed: String = String("")
  private var _currentDirection: String = String("")
  
  //--------------------------------------------------------------//
  // MARK: -- 初期化 --
  //--------------------------------------------------------------//
  private override init() {
    speechStrings = String("")    
    super.init()
  }

  //--------------------------------------------------------------//
  // MARK: -- パブリックメソッド --
  //--------------------------------------------------------------//
  public func updateLocation(location:CLLocation) {
    // 速度を取得する
    let currentSpd = round(location.speed * 10) / 10 // XX.X m/s
    self._currentSpeed = String(format: "%.1f", currentSpd)
  }
  
  public func updateHeading(heading:CLHeading) {
    // 方角を取得する
    let currentDir = Int(round(heading.trueHeading)) // course/360 degree
    self._currentDirection = String(format: "%03d", currentDir)
  }

  //--------------------------------------------------------------//
  // MARK: -- プライベートメソッド --
  //--------------------------------------------------------------//
}
