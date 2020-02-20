//
//  ZApp.swift
//  ztop
//
//  Created by Zach Eriksen on 8/28/18.
//  Copyright © 2018 oneleif. All rights reserved.
//

import Foundation

struct ZApp: Codable {
    let name: String
    let p_id: pid_t
    let cpu: Double
    let mem: Double
    var tick: Int = 0
    var isPinned: Bool = false {
        didSet {
            if oldValue {
                "renice -n \(0) -p \(p_id)".run()
            }
        }
    }
    var limit: Double = 0 {
        didSet {
            isPinned = limit != 0
            if limit > 0 {
                "renice -n \(limit) -p \(p_id)".run()
            }
        }
    }
    
    mutating func limit(percent: Double) {
        limit = percent
    }
}
