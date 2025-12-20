//
//  File.swift
//  Billiards
//
//  Created by mac on 2025/11/14.
//

import Foundation
import UIKit

extension UIApplication {
    /// 获取当前顶层的 UIViewController（用于弹出系统窗口）
    var topMostViewController: UIViewController? {
        guard let window = connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else { return nil }
        
        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
