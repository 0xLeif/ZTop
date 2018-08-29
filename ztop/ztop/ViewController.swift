//
//  ViewController.swift
//  ztop
//
//  Created by Zach Eriksen on 8/28/18.
//  Copyright © 2018 oneleif. All rights reserved.
//

import Cocoa
import Repeat
// currentSelectedCell
// limittedApps
// touchBar
class ViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var limitedTableView: NSTableView!
    @IBOutlet weak var limitedView: NSScrollView!
    fileprivate var globalTick: Int = 0
    fileprivate var selectedApp: ZApp? = nil {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate var timer: Repeater!
    fileprivate var limitedApps: [ZApp] = [] {
        didSet {
            DispatchQueue.main.async {
                self.limitedTableView.reloadData()
                self.limitedView.isHidden = self.limitedApps.isEmpty
            }
        }
    }
    fileprivate var apps: [ZApp] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate var allApps: [String: ZApp] = [:] {
        didSet {
            apps = allApps.values.filter({ (app) -> Bool in
                !app.isPinned
            })
                .sorted { $0.cpu > $1.cpu }
            limitedApps = allApps.values
                .filter { (app) -> Bool in
                app.isPinned
            }
                .sorted { $0.cpu > $1.cpu }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadApps()
        limitedApps = []
        linkTableViews()
        timer = Repeater.every(.seconds(1)) { (r) in
            self.updateApps()
        }
    }
    
    fileprivate func linkTableViews() {
        tableView.target = self
        tableView.action = #selector(limitApp)
        limitedTableView.target = self
        limitedTableView.action = #selector(freeApp)
        tableView.delegate = self
        tableView.dataSource = self
        limitedTableView.delegate = self
        limitedTableView.dataSource = self
    }
    
    fileprivate func loadApps() {
        apps = NSWorkspace.shared.runningApplications
            .filter { $0.localizedName != "ztop" }
            .compactMap { get(app: $0) }
            .sorted { $0.cpu > $1.cpu }
        apps.forEach { (app) in
            allApps["\(app.p_id)"] = app
            allApps["\(app.p_id)"]?.tick = globalTick
        }
    }
    
    fileprivate func updateApps() {
        globalTick += 1
        NSWorkspace.shared.runningApplications
            .filter { $0.localizedName != "ztop" }
            .compactMap { get(app: $0) }
            .forEach { (app) in
                if let oldApp = allApps["\(app.p_id)"] {
                    allApps["\(app.p_id)"] = app
                    allApps["\(app.p_id)"]?.limit(percent: oldApp.limit)
                    
                } else {
                    allApps["\(app.p_id)"] = app
                }
                allApps["\(app.p_id)"]?.tick = globalTick
        }
        allApps.values
            .filter { $0.tick != globalTick }
            .forEach { allApps["\($0.p_id)"] = nil }
    }
        
    @objc
    fileprivate func limitApp() {
        if tableView.clickedRow >= 0 {
            print(tableView.clickedRow)
            let app = apps[tableView.clickedRow]
            allApps["\(app.p_id)"]!.limit(percent: 50)
        }
    }
    
    @objc
    fileprivate func freeApp() {
        if limitedTableView.clickedRow >= 0 {
            print(limitedTableView.clickedRow)
            let app = limitedApps[limitedTableView.clickedRow]
            allApps["\(app.p_id)"]!.limit(percent: 0)
        }
    }
}

extension ViewController: NSTableViewDelegate,
                            NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableView == limitedTableView ? limitedApps.count : apps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == limitedTableView {
            guard let cell = tableView.makeView(withIdentifier: (tableColumn?.identifier)!, owner: nil) as? NSTableCellView else {
                return nil
            }
            var text: String = ""
            if row >= limitedApps.count {
                limitedTableView.reloadData()
                return nil
            }
            let item = limitedApps[row]
            
            if tableColumn == tableView.tableColumns[0] {
                text = item.name
            } else if tableColumn == tableView.tableColumns[1] {
                text = "\(item.cpu)"
            } else if tableColumn == tableView.tableColumns[2] {
                text = "\(item.mem)"
            } else if tableColumn == tableView.tableColumns[3] {
                text = "\(item.limit)"
                cell.textField?.isEditable = true
            }
            
            cell.textField?.stringValue = text
            
            return cell
        } else {
            guard let cell = tableView.makeView(withIdentifier: (tableColumn?.identifier)!, owner: nil) as? NSTableCellView else {
                return nil
            }
            var text: String = ""
            if row >= apps.count {
                tableView.reloadData()
                return nil
            }
            let item = apps[row]
            
            if tableColumn == tableView.tableColumns[0] {
                text = item.name
            } else if tableColumn == tableView.tableColumns[1] {
                text = "\(item.cpu)"
            } else if tableColumn == tableView.tableColumns[2] {
                text = "\(item.mem)"
            }
            
            cell.textField?.stringValue = text
           
            return cell
        }
    }
}
