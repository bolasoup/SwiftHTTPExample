//
//  ClientModel.swift
//  HTTPSwiftExample
//
//  Created by Eric Cooper Larson on 6/3/24.
//  Copyright © 2024 Eric Larson. All rights reserved.
//

protocol ClientDelegate{
    func receiveResponse(response:Any, strData:Any)
}

enum RequestEnum:String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

import UIKit

class ClientModel: NSObject, URLSessionDelegate {
    
    //MARK: Properties and Delegation
    let operationQueue = OperationQueue()
    var server_ip = "127.0.0.1" // this will be the default ip
    // create a delegate for using the protocol
    var delegate:ClientDelegate?
    
    lazy var session = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        let tmp = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        return tmp
        
    }()
    
    //MARK: Setters and Getters
    func setServerIp(ip:String)->(Bool){
        // user is trying to set ip: make sure that it is valid ip address
        if matchIp(for:"((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\.|$)){4}", in: ip){
            server_ip = ip
            // return success
            return true
        }else{
            return false
        }
    }
    
    
    //MARK: Main Functions
    
    // Call Hello World on the App
    func connectToRoot(){
        let baseURL = "http://\(server_ip):8000/"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                        completionHandler:{(data, response, error) in
            // TODO: handle error!
            let jsonDictionary = self.convertDataToDictionary(with: data)
                            
            if let delegate = self.delegate, let resp=response {
                delegate.receiveResponse(response: resp, strData: jsonDictionary)
            }

        })
        
        postTask.resume() // start the task
        
    }
    
    
    // List all the Characters in the app
    func listCharacters(){
        let baseURL = "http://\(server_ip):8000/characters"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                        completionHandler:{(data, response, error) in
            // TODO: handle error!
            let jsonDictionary = self.convertDataToDictionary(with: data)
                            
            if let delegate = self.delegate, let resp=response {
                delegate.receiveResponse(response: resp, strData: jsonDictionary)
            }

        })
        
        postTask.resume() // start the task
        
    }
    
    
    func addCharacter(_ character:[String: Any]){
        let baseURL = "http://\(server_ip):8000/characters"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // utility method to use from below
        let requestBody:Data = try! JSONSerialization.data(withJSONObject: character)
        
        // The Type of the request is given here
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                        completionHandler:{(data, response, error) in
            // TODO: handle error!
            let jsonDictionary = self.convertDataToDictionary(with: data)
                            
            if let delegate = self.delegate {
                delegate.receiveResponse(response: response!, strData: jsonDictionary)
            }

        })
        
        postTask.resume() // start the task
    }
    
    func updateCharacter(_ character:[String: Any]){
        self.restUtility(character, requestType: .put)
    }
    
    func findCharacter(_ character:[String: Any]){
        self.restUtility(character, requestType: .get)
    }
    
    func deleteCharacter(_ character:[String: Any]){
        self.restUtility(character, requestType: .delete)
    }
    
    
    private func restUtility(_ character:[String: Any], requestType:RequestEnum){
        guard let name = character["name"] else{
            return
        }
        let baseURL = "http://\(server_ip):8000/characters/\(name)"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // utility method to use from below
        let requestBody:Data = try! JSONSerialization.data(withJSONObject: character)
        
        // The Type of the request is given here
        request.httpMethod = requestType.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requestType != .get{
            // if not a get request, then we need a body
            // otherwise we cannot add a body to a get request
            request.httpBody = requestBody
        }
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                        completionHandler:{(data, response, error) in
            // TODO: handle error!
            // any URL or domain errors will not be caught
            
            var jsonDictionary = [String:Any]()
            if requestType != .delete{
                jsonDictionary = self.convertDataToDictionary(with: data)
            }
                            
            if let delegate = self.delegate {
                delegate.receiveResponse(response: response!, strData: jsonDictionary)
            }

        })
        
        postTask.resume() // start the task
    }

    
    //MARK: Utility Functions
    private func matchIp(for regex:String, in text:String)->(Bool){
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            if results.count > 0{return true}
            
        } catch _{
            return false
        }
        return false
    }
    
    private func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        // convenience function for serialiing an NSDictionary
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    

    
    private func convertDataToDictionary(with data:Data?)->[String:Any]{
        // convenience function for getting Dictionary from server data
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: [String:Any] =
                try JSONSerialization.jsonObject(with: data!,
                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as! [String : Any]
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            if let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                print("printing JSON received as string: "+strData)
            }
            return [String:Any]() // just return empty
        }
    }
}
