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
    @IBOutlet weak var startMonthLabel: UILabel!
    @IBOutlet weak var startDayLabel: UILabel!
    @IBOutlet weak var endMonthLabel: UILabel!
    @IBOutlet weak var endDayLabel: UILabel!
    @IBOutlet weak var contestGoalLabel: UILabel!
    @IBOutlet weak var dayCardView: UIView!
    @IBOutlet weak var stepProgressBar: UIProgressView!
   
    @IBAction func startDateButtonTouched(_ sender: UIButton) {
        showDateInputDialog(buttonID: "Start")
    }
    
    @IBAction func endDateButtonTouched(_ sender: UIButton) {
        showDateInputDialog(buttonID: "End")
    }
    
    @IBAction func goalButtonTouched(_ sender: UIButton) {
        showGoalInputDialog() 
    }
    
    
    let storage = HKHealthStore()
    var todayStepCount:Float = 0
    var contestGoalStepCount:Float = 70000
    var startDateString = "2018-02-13"
    var endDateString = "2018-02-15"

    
    
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
        
        
        //  prepare the predicate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDate = dateFormatter.date(from: startDateString)
        let endDate = dateFormatter.date(from: endDateString)
        let endDateForQuery = NSCalendar.current.date(byAdding: .day, value: 1, to: endDate!) // add a day to include the last day

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDateForQuery, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsCount!,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { query, result, error in
                                        
            if error != nil {
                
                //  Something went Wrong
                print("Something went wrong")
                return
            }

            
            
            if let quantity = result?.sumQuantity() {
                let steps = quantity.doubleValue(for: HKUnit.count())
                completion(steps)
            }
        }

        
        
        storage.execute(query)
    }
    
    func refreshView() {
        
        // Update the Calendar labels
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDate = dateFormatter.date(from: startDateString)
        let endDate = dateFormatter.date(from: endDateString)

        
        let dateMonthFormatter = DateFormatter()
        dateMonthFormatter.dateFormat = "MMM"
        
        let dateDayFormatter = DateFormatter()
        dateDayFormatter.dateFormat = "dd"
        
        

        
        let startDateMonth = dateMonthFormatter.string(from: startDate!)
        let startDateDay = dateDayFormatter.string(from: startDate!)
        let endDateMonth = dateMonthFormatter.string(from: endDate!)
        let endDateDay = dateDayFormatter.string(from: endDate!)

        startMonthLabel.text = startDateMonth
        startDayLabel.text = startDateDay
        endMonthLabel.text = endDateMonth
        endDayLabel.text = endDateDay
        
        
        // Update the Daily Goal label
        contestGoalLabel.text = makeDecimalString(theNumber: contestGoalStepCount)
        
        // Update the Stepcount label
        HealthKitSetupAssistant.authorizeHealthKit { (success, error) in
            if success {
                self.retrieveStepCount { (stepCount) in
                    DispatchQueue.main.async {
                        // Update Today's Steps label and progress bar
                        self.stepCountLabel.text = self.makeDecimalString(theNumber: Float(Int(stepCount)))
                        self.todayStepCount = Float(stepCount)
                        
                        self.stepProgressBar.progress = self.todayStepCount / self.contestGoalStepCount
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
        refreshView()
    }
    
    
    func showDateInputDialog(buttonID: String) {

        //Setting title and message for the alert dialog
        let alertController = UIAlertController(title: "Enter New Date String", message: "Format yyyy-mm-dd", preferredStyle: .alert)
        
        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            
            //getting the input values from user
            let inputDateString = (alertController.textFields?[0].text)!
            
            // validate string
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            

            if dateFormatter.date(from: inputDateString) != nil {
                
                if buttonID == "Start" {
                    self.startDateString = inputDateString
                } else if buttonID == "End" {
                    self.endDateString = inputDateString
                }
                self.refreshView()

            } else {
                // invalid format
                print("invalid date format")
            }
            
        }
        
        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.placeholder = "yyyy-mm-dd"
        }
        
        //adding the action to dialogbox
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showGoalInputDialog() {
        //Creating UIAlertController and
        //Setting title and message for the alert dialog
        
        
        let alertController = UIAlertController(title: "Contest Goal", message: "Please enter a new step goal for this contest.", preferredStyle: .alert)
        
        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            
            //getting the input values from user
            let inputDateString = (alertController.textFields?[0].text)!
            self.contestGoalStepCount = Float(inputDateString)!
            self.refreshView()
            
        }
        
        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.placeholder = "70000"
        }
        
        //adding the action to dialogbox
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        self.present(alertController, animated: true, completion: nil)
    }

    deinit {
        // perform the deinitialization
        
        // Remove the notification
        NotificationCenter.default.removeObserver(self)
    }

}

