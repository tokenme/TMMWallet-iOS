//
//  UITableView+Utils.swift
//  ucoin
//
//  Created by Syd on 2018/6/11.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit

extension UITableView {
    func reloadDataWithAutoSizingCellWorkAround() {
        self.rowHeight = UITableView.automaticDimension
        self.reloadData()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

extension UICollectionView {
    func reloadDataWithAutoSizingCellWorkAround() {
        self.reloadData()
        //self.collectionViewLayout.invalidateLayout()
        //self.setNeedsLayout()
        //self.layoutIfNeeded()
    }
}
