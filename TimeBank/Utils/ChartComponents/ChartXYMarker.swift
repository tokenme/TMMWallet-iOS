//
//  ChartXYMarker.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/1.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import Charts

public class XYMarkerView: ChartBalloonMarker {
    public var xAxisValueFormatter: IAxisValueFormatter
    fileprivate var yFormatter = NumberFormatter()
    
    public init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets,
                xAxisValueFormatter: IAxisValueFormatter) {
        self.xAxisValueFormatter = xAxisValueFormatter
        yFormatter.minimumFractionDigits = 0
        yFormatter.maximumFractionDigits = 4
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        guard let data = entry.data as? APIMarketGraph else { return }
        let string = xAxisValueFormatter.stringForValue(entry.x, axis: XAxis())
            + "\nQuantity: "
            + yFormatter.string(from: data.quantity)!
        setLabel(string)
    }
    
}
