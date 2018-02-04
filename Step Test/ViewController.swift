//
//  ViewController.swift
//  Step Test
//
//  Created by Seth Levine on 1/24/18.
//  Copyright © 2018 Seth Levine. All rights reserved.
//

import UIKit
import HealthKit


class ViewController: UIViewController {

    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dailyGoalLabel: UILabel!
    @IBOutlet weak var dayCardView: UIView!
    @IBOutlet weak var stepProgressBar: UIProgressView!
    
    let storage = HKHealthStore()
    var todayStepCount:Float = 0
    var dailyGoalStepCount:Float = 10000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.dayCardView.layer.cornerRadius = 10 
        self.stepProgressBar.transform = stepProgressBar.transform.scaledBy(x: 1, y: 10)
        refreshView()
        
        // Add a listener for when the app will enter foreground then refresh view
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func retrieveStepCount(completion: @escaping (_ stepRetrieved: Double) -> Void) {
        
        //   Define the Step Quantity Type
        let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        
        // TODO: Change to 'start of the match'
        //   Get the start of the day
        let date = Date()
//        var startDate = Date()
//        let startDateFormatter = DateFormatter()
//        startDateFormatter.dateFormat = "yyyy-MM-DD"
//        let startDateString = "2017-01-01"
//        startDate = startDateFormatter.date(from: startDateString)!

        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        
        //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1
        
        //  Perform the Query
        let query = HKStatisticsCollectionQuery(quantityType: stepsCount!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: newDate as Date, intervalComponents:interval)
        
        query.initialResultsHandler = { query, results, error in
            
            if error != nil {
                
                //  Something went Wrong
                return
            }
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)

            if let myResults = results{
                myResults.enumerateStatistics(from: startOfDay, to: now) {
                    statistics, stop in
                    
                    if let quantity = statistics.sumQuantity() {
                        
                        let steps = quantity.doubleValue(for: HKUnit.count())
                        
                        completion(steps)
                        
                    }
                }
            }
            
            
        }
        
        storage.execute(query)
    }
    
    func refreshView() {
        // Update the Calendar labels
        let todayDate = Date()
        
        let todayMonthFormatter = DateFormatter()
        todayMonthFormatter.dateFormat = "MMM"
        
        let todayDayFormatter = DateFormatter()
        todayDayFormatter.dateFormat = "dd"

        let todayDay = todayDayFormatter.string(from: todayDate)
        let todayMonth = todayMonthFormatter.string(from: todayDate)

        monthLabel.text = todayMonth
        dayLabel.text = todayDay
        
        
        // Update the Daily Goal label
        dailyGoalLabel.text = makeDecimalString(theNumber: dailyGoalStepCount)
        
        // Update the Stepcount label
        HealthKitSetupAssistant.authorizeHealthKit { (success, error) in
            if success {
                self.retrieveStepCount { (stepCount) in
                    DispatchQueue.main.async {
                        // Update Today's Steps label and progress bar
                        self.stepCountLabel.text = self.makeDecimalString(theNumber: Float(Int(stepCount)))
                        self.todayStepCount = Float(stepCount)
                        
                        self.stepProgressBar.progress = self.todayStepCount / self.dailyGoalStepCount
                    }
                }
            }
        }

    }
    
    func makeDecimalString(theNumber: Float) -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:theNumber))
        return formattedNumber!
    }
    
     
    @objc func appMovedToForeground() {
        print("App moved to ForeGround!")
        refreshView()
    }
    
    
}

