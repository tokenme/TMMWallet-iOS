//
//  ChartTimeFormatter.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/1.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import Charts

public class ChartTimeFormatter: NSObject, IAxisValueFormatter {
    private let dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        dateFormatter.dateFormat = "HH'h'dd'd'"
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
