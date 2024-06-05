//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py 
//              from the course GitHub repository: tornado_bare, branch turi_create_examples



import UIKit

class ViewController: UIViewController, ClientDelegate {
    
    //MARK: Properties
    let client = ClientModel() // how we will interact with the server
    
    //MARK: View Outlets
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var ipAddressTextView: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var powerTextField: UITextField!
    @IBOutlet weak var kindTextField: UITextField!
    @IBOutlet weak var levelSlider: UISlider!
    
    //MARK: Lazy Computed Properties
    lazy var animation = {
        let tmp = CATransition()
        // create reusable animation, for updating the server
        tmp.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        tmp.type = CATransitionType.reveal
        tmp.duration = 0.5
        return tmp
    }()
      
    
    //MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // be the delegate various things
        self.ipAddressTextView.delegate = self
        self.nameTextField.delegate = self
        self.powerTextField.delegate = self
        self.kindTextField.delegate = self
        self.client.delegate = self
        
        // setup the class for session
        self.ipAddressTextView.text = client.server_ip
    }
    
    //MARK: View Actions
    @IBAction func helloWorld(_ sender: AnyObject) {
        client.connectToRoot()
    }
    
    @IBAction func listCharacters(_ sender: AnyObject) {
        client.listCharacters()
    }
    
    
    @IBAction func createRequest(_ sender: AnyObject) {
        if let character = getCharacterAttributes(){
            client.addCharacter(character)
        }
    }
    
    @IBAction func getRequest(_ sender: AnyObject) {
        if let character = getCharacterAttributes(){
            client.findCharacter(character)
        }
    }
    
    @IBAction func updateRequest(_ sender: AnyObject) {
        if let character = getCharacterAttributes(){
            client.updateCharacter(character)
        }
    }
    
    @IBAction func deleteRequest(_ sender: AnyObject) {
        if let character = getCharacterAttributes(){
            client.deleteCharacter(character)
        }
    }

    //MARK: Utility
    func getCharacterAttributes() -> [String:Any]?{
        
        let level = Int(levelSlider.value)
        if let name = nameTextField.text,
           let power = powerTextField.text,
           let kind = kindTextField.text{
            
            // if here, all the attributes worked out
            let tmpDict:[String:Any] = ["name":name, "power":power, "kind":kind, "level": level]
            return tmpDict
            
        }
        return nil
    }
}


//MARK: TextFieldDelegate methods
// if you do not know your local sharing server name try:
//    ifconfig |grep inet
// to see what your public facing IP address is, the ip address can be used here
extension ViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //TODO: setup responders in order
        // name->power->kind-resign
        // ip->resign
        switch textField {
        case nameTextField:
            // this is the name, go to power
            powerTextField.becomeFirstResponder()
        case powerTextField:
            kindTextField.becomeFirstResponder()
        case kindTextField:
            textField.resignFirstResponder()
        case ipAddressTextView:
            // update the ip address
            if let ipString = textField.text{
                // change the ip of server
                if client.setServerIp(ip: ipString){
                    // if successful, show the ip
                    DispatchQueue.main.async {
                        self.ipAddressTextView.text = ipString
                    }
                }
            }
            textField.resignFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        
        
        return true
    }
    
    
}


//MARK: Utility Extending Functions
extension ViewController {
        
    func receiveResponse(response:Any, strData:Any){
        // convenience function meant for displaying the response and the
        // extra argument data from an HTTP request completion
        DispatchQueue.main.async{
            self.mainTextView.layer.add(self.animation, forKey: nil)
            self.mainTextView.text = "\(response) \n==================\n\(strData)"
        }
    }
    
    
}



