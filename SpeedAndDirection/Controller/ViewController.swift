//
//  ViewController.swift
//  SpeedAndDirection
//
//  Created by MK on 2018/11/08.
//  Copyright © 2018 NotenkiApps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet weak var speedTextField: UILabel!
  @IBOutlet weak var directionTextField: UILabel!
  @IBOutlet weak var startSpeekSpeedSwitch: UISwitch!
  @IBOutlet weak var startSpeekDirectionSwitch: UISwitch!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    // 通知を登録する
    let center = NotificationCenter.default
    center.addObserver(self,
                       selector: #selector(type(of: self).notified_NTKDataManagerDidUpdatedData(notification:)),
                       name: NTKModelManager.sharedInstance.NTKDataManagerDidUpdateLocation,
                       object: nil)

    // スピーチ機能をOnにする
    self.startSpeekSpeedSwitch.setOn(true, animated: false)
    NTKModelManager.sharedInstance.startSpeekSpeed()
    self.startSpeekDirectionSwitch.setOn(true, animated: false)
    NTKModelManager.sharedInstance.startSpeekDirection()

    // ModelManagerの動作を開始する
    NTKModelManager.sharedInstance.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    // 通知の受け取りを解除する
    let center = NotificationCenter.default
    center.removeObserver(self)
  }
  
  @IBAction func startSpeekSpeedSwitchPressed(_ sender: Any) {
    if startSpeekSpeedSwitch.isOn {
      NTKModelManager.sharedInstance.startSpeekSpeed()
    }
    else {
      NTKModelManager.sharedInstance.stopSpeekSpeed()
    }
  }
  
  @IBAction func startSpeekDirectionSwitchPressed(_ sender: Any) {
    if startSpeekDirectionSwitch.isOn {
      NTKModelManager.sharedInstance.startSpeekDirection()
    }
    else {
      NTKModelManager.sharedInstance.stopSpeekDirection()
    }
  }
  
  @objc private func notified_NTKDataManagerDidUpdatedData(notification: Notification) {
    // 表示を更新する
    if let currentSpeed = notification.userInfo?["currentSpeed"] as? String {
      self.speedTextField.text = currentSpeed
    }
    if let currentDirection = notification.userInfo?["currentDirection"] as? String {
      self.directionTextField.text = currentDirection
    }
  }
}
