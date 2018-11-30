//
//  Time+Utils.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import GrandTime

extension Int {
    func timeSpan() -> String {
        let tn = TimeSpan(ticks: self * 1000)
        var res: String = ""
        if tn.days > 0 {
            res += "\(tn.days)d"
        }
        if tn.hours > 0 {
            res += "\(tn.hours)h"
        }
        if tn.minutes > 0 {
            res += "\(tn.minutes)m"
        }
        if tn.seconds > 0 {
            res += "\(tn.seconds)s"
        }
        return res
    }
}

extension Date {
    func daysBetweenDate(toDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: toDate)
        return components.day ?? 0
    }
}
