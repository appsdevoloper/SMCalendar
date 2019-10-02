//
//  ViewController.swift
//  CustomCalendar
//
//  Created by Apple on 28/09/19.
//  Copyright © 2019 appzoo. All rights reserved.
//

import UIKit

// MARK: JSON Structure For Calendar

struct Calendars: Codable {
    let status: Bool
    let data: [Cdata]
}

struct Cdata: Codable {
    let count: Int
    let startdate: String
}

// MARK: JSON Structure For Event List

struct Events: Codable {
    let status: Bool
    let data: [Edata]
}

struct Edata: Codable {
    let title, date: String
}

class MyCustomCell: UITableViewCell {

}

class CalendarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
        }()
    
    var calendarsData = [Cdata]()
    var eventsData = [Edata]()
    //var calendarsDataString = [String]()
    //var datesWithEvent = ["02-09-2019", "03-09-2019", "07-09-2019", "09-09-2019"]
    //var datesWithMultipleEvents = ["03-09-2019", "03-09-2019", "02-09-2019", "09-09-2019"]
    //let eventsData: [String] = ["LDA #1", "LDA #2", "LDA #3", "LDA #4", "LDA #5", "LDA #6", "LDA #7", "LDA #8"]
    let cellReuseIdentifier = "cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.model.hasPrefix("iPad") {
            self.calendarHeightConstraint.constant = 400
        }
        
        self.calendar.select(Date())
        
        self.view.addGestureRecognizer(self.scopeGesture)
        self.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.calendar.scope = .week
        
        // For UITest
        self.calendar.accessibilityIdentifier = "calendar"
        
        self.loadCalendarsJSON()
        self.loadEventsJSON(selectedDate: "09-09-2019")
    }
    
    deinit {
        print("\(#function)")
    }
    
    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }
    
    // MARK:- UICalendarDataSource
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("did select date \(self.dateFormatter.string(from: date))")
        self.loadEventsJSON(selectedDate:dateFormatter.string(from: date))
        //let selectedDates = calendar.selectedDates.map({self.dateFormatter.string(from: $0)})
        //print("selected dates is \(selectedDates)")
        //if monthPosition == .next || monthPosition == .previous {
            //calendar.setCurrentPage(date, animated: true)
        //}
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("\(self.dateFormatter.string(from: calendar.currentPage))")
    }
    
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateString = self.dateFormatter.string(from: date)
        
        for item in calendarsData {
            if item.startdate.contains(dateString) {
                return item.count
            }
            
            //if item.startdate.contains(dateString) {
                //return item.count
            //}
        }
        return 0
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        //let key = self.dateFormatter.string(from: date)
        //if self.datesWithMultipleEvents.contains(key) {
            //return [UIColor.magenta, appearance.eventDefaultColor, UIColor.black]
        //}
        return nil
    }
    
    // MARK:- UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [2,self.eventsData.count][section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let identifier = ["cell_month", "cell_week"][indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
            return cell
        } else {
            let item = self.eventsData[indexPath .row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
                cell.textLabel?.text = item.title
            return cell
        }
    }
    
    // MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let scope: FSCalendarScope = (indexPath.row == 0) ? .month : .week
            self.calendar.setScope(scope, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    // MARK:- Target actions
    
    @IBAction func toggleClicked(sender: AnyObject) {
        if self.calendar.scope == .month {
            self.calendar.setScope(.week, animated: true)
        } else {
            self.calendar.setScope(.month, animated: true)
        }
    }
    
    // MARK: JSON Data Load - Calendar Data
    
    func loadCalendarsJSON(){
        
        let urlPath = ""
        let url = NSURL(string: urlPath)
        let session = URLSession.shared
        let task = session.dataTask(with: url! as URL) { data, response, error in
            guard data != nil && error == nil else {
                print(error!.localizedDescription)
                return
            }
            do {
                let decoder = try JSONDecoder().decode(Calendars.self,  from: data!)
                let status = decoder.status
                if status == true {
                    self.calendarsData = decoder.data
                    print(self.calendarsData)
                    /*for item in decoder.data {
                     self.calendarsDataString = [item.startdate]
                     print(item.startdate)
                     print(self.calendarsDataString)
                     }*/
                    DispatchQueue.main.async {
                        self.calendar.reloadData()
                    }
                } else {
                    
                }
            } catch { print(error) }
        }
        task.resume()
    }
    
    // MARK: JSON Data Load - Events List

    func loadEventsJSON(selectedDate: String){
        
        print("DATE RECEIVED: \(selectedDate)")
        let urlPath = ""
        let url = NSURL(string: urlPath)
        let session = URLSession.shared
        let task = session.dataTask(with: url! as URL) { data, response, error in
            guard data != nil && error == nil else {
                print(error!.localizedDescription)
                return
            }
            do {
                let decoder = try JSONDecoder().decode(Events.self,  from: data!)
                let status = decoder.status
                if status == true {
                    self.eventsData = decoder.data
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } else {
                    
                }
            } catch { print(error) }
        }
        task.resume()
    }
}

