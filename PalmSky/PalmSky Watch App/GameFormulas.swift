//
//  GameFormulas.swift
//  PalmSky Watch App
//
//  Created by mac on 12/14/25.
//

import Foundation

import Foundation

extension Double {
    // 修仙专用数值格式化 (万进法)
    var xiuxianString: String {
        let units = ["", "万", "亿", "兆", "京", "垓", "秭", "穰", "沟", "涧", "正", "载", "极"]
        var value = self
        var index = 0
        
        // 核心逻辑：只要大于 10000 且还有更大的单位，就除以 10000
        while value >= 10000 && index < units.count - 1 {
            value /= 10000
            index += 1
        }
        
        // 格式化输出
        if index == 0 {
            // 小于 1万，直接显示整数 (如: 9527)
            return String(format: "%.0f", value)
        } else {
            // 大于 1万，保留两位小数 (如: 1.25亿)
            // 优化：如果数字大于 100 (如 500.23万)，为了布局好看，可以只保留1位小数
            // 这里统一保留2位，视觉最稳
            return String(format: "%.2f%@", value, units[index])
        }
    }
}

extension Double {
    var gameCurrencyString: String {
        let num = self
        if num < 1000 { return String(format: "%.0f", num) }
        if num < 1_000_000 { return String(format: "%.2fK", num / 1000) }
        if num < 1_000_000_000 { return String(format: "%.2fM", num / 1_000_000) }
        if num < 1_000_000_000_000 { return String(format: "%.2fB", num / 1_000_000_000) }
        return String(format: "%.2fT", num / 1_000_000_000_000)
    }
}

