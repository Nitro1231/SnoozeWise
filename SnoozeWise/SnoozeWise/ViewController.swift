//
//  ViewController.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/21/24.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var sleepData: [SleepData] = [] // Store fetched sleep data here

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        
        // Assuming you have a way to pass the fetched sleep data to this ViewController
        HealthDataManager.fetchSleepAnalysis(<#HealthDataManager#>)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sleepData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let data = sleepData[indexPath.row]
        cell.textLabel?.text = "Start: \(data.start_time), End: \(data.end_time), Stage: \(data.stage)"
        
        return cell
    }
}
