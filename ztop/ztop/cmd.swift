//
//  cmd.swift
//  ztop
//
//  Created by Zach Eriksen on 8/28/18.
//  Copyright © 2018 oneleif. All rights reserved.
//

import Cocoa

extension String {
    @discardableResult
    func run() -> String? {
        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", self]
        process.standardOutput = pipe
        
        let fileHandle = pipe.fileHandleForReading
        process.launch()
        
        return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
    }
}

func get(app: NSRunningApplication) -> ZApp? {
    let p_id = app.processIdentifier
    guard let name = app.localizedName,
        let cpu = "ps -p \(p_id) -o %cpu".run(),
        let mem = "ps -p \(p_id) -o %mem".run(),
        let formattedCPU = Double(cpu.replacingOccurrences(of: "%CPU", with: "").trimmingCharacters(in: .whitespacesAndNewlines)),
        let formattedMEM = Double(mem.replacingOccurrences(of: "%MEM", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
    }
    return ZApp(name: name, p_id: p_id, cpu: formattedCPU, mem: formattedMEM, isPinned: false, limit: 0)
}
