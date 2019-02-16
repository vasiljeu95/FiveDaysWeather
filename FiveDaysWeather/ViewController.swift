//
//  ViewController.swift
//  FiveDaysWeather
//
//  Created by Stepan Vasiljeu on 2/16/19.
//  Copyright © 2019 Stepan Vasiljeu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate  {
    
    //MARK: - QUEUE
    let requestQueue = DispatchQueue.global(qos: .userInitiated)
    let jsonParsingQueue = DispatchQueue.global(qos: .userInitiated)
    
    //MARK: - CELL
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return linksInItem.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "googleSearchAddressCell", for: indexPath)
        cell.textLabel!.text = linksInItem[indexPath.row]
        return cell
    }
    
    //MARK: - OUTLET
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var weatherSegmentedControl: UISegmentedControl!
    
    private var linksInItem : Array<String> = []
    private var downloadURL: URLSessionTask = URLSessionTask()
    
    private var processingRequest = false
    
    //MARK: - FUNCTION
    // https://api.openweathermap.org/data/2.5/forecast?lat=37.78&lon=-122.40&appid=4d24cbf9d70b0c3cedc62cc36c70ec13
    private func urlCitySearchRequest(searchText: String) -> URL? {
        let appid = "4d24cbf9d70b0c3cedc62cc36c70ec13"
        let cityApi: String = searchText.replacingOccurrences(of: " ", with: "%20")
        
        if let url = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=" + cityApi + "&appid=" + appid) {
            return url
        } else {
            return nil
        }
    }
    
    private func urlLocationSearchRequest(searchText: String) -> URL? {
        let appid = "4d24cbf9d70b0c3cedc62cc36c70ec13"
        let locationCoordinateAPI: String = searchText.replacingOccurrences(of: ", ", with: "&lon=")
        
        if let url = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=" + locationCoordinateAPI + "&appid=" + appid) {
            return url
        } else {
            return nil
        }
    }
    
    private func downloadJson() {
        searchTextField.endEditing(true)
        processingRequest = true
        if weatherSegmentedControl.selectedSegmentIndex == 0 {
            if let url = urlCitySearchRequest(searchText: searchTextField.text!) {
                self.downloadURL = URLSession.shared.dataTask(with: url) {
                    (data, urlResponse, error) in
                    guard let data = data else {return}
                    do {
                        try self.jsonParsingQueue.sync {
                            let decoder = try JSONDecoder().decode(FiveDaysWeatherJSON.self, from: data)
                            if decoder.list != nil {
                                self.linksInItem.removeAll()
                                decoder.list!.forEach{
                                    print($0.dtTxt!)
                                    self.linksInItem.append($0.dtTxt!)
                                }
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    } catch {
                        print(error)
                    }
                    self.beforeSearch()
                    self.processingRequest = false
                }
                requestQueue.async {
                    self.duringSearch()
                    self.downloadURL.resume()
                }
            } else {
                print("Invalid url")
            }
        }
        
        if weatherSegmentedControl.selectedSegmentIndex == 1 {
            if let url = urlLocationSearchRequest(searchText: searchTextField.text!) {
                self.downloadURL = URLSession.shared.dataTask(with: url) {
                    (data, urlResponse, error) in
                    guard let data = data else {return}
                    do {
                        try self.jsonParsingQueue.sync {
                            let decoder = try JSONDecoder().decode(FiveDaysWeatherJSON.self, from: data)
                            if decoder.list != nil {
                                self.linksInItem.removeAll()
                                decoder.list!.forEach{
                                    print($0.dtTxt!)
                                    self.linksInItem.append($0.dtTxt!)
                                }
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    } catch {
                        print(error)
                    }
                    self.beforeSearch()
                    self.processingRequest = false
                }
                requestQueue.async {
                    self.duringSearch()
                    self.downloadURL.resume()
                }
            } else {
                print("Invalid url")
            }
        }
    }
    
    private func stopSearch(){
        self.requestQueue.async {
            self.downloadURL.cancel()
        }
        print("Search stopped")
        self.processingRequest = false
        beforeSearch()
    }
    
    private func buttonTheSearch(){
        if !processingRequest {
            downloadJson()
        } else {
            stopSearch()
        }
    }
    
    private func duringSearch(){
        DispatchQueue.main.async {
            self.searchButton.setTitle("Stop", for: .normal)
        }
    }
    
    private func beforeSearch(){
        DispatchQueue.main.async {
            self.searchButton.setTitle("Google Search", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchButton.setTitle("Google Search", for: .normal)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissText))
        view.addGestureRecognizer(tapGesture)
        
        searchTextField.returnKeyType = UIReturnKeyType.search
        searchTextField.delegate = self
    }
    
    @IBAction func pressSearchButton(_ sender: UIButton) {
        buttonTheSearch()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.searchTextField {
            buttonTheSearch()
        }
        return true
    }
    
    @objc func dismissText(){
        searchTextField.endEditing(true)
    }
    
}

