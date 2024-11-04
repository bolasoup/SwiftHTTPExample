//
//  CMLViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson
//  Copyright © 2024 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion
import CoreML

class CMLViewController: UIViewController {

    // Motion data
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    
    let motionOperationQueue = OperationQueue()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = true
    
    @IBOutlet weak var upArrow: UILabel!
    @IBOutlet weak var rightArrow: UILabel!
    @IBOutlet weak var downArrow: UILabel!
    @IBOutlet weak var leftArrow: UILabel!
    @IBOutlet weak var largeMotionMagnitude: UIProgressView!
    
    var stateOut:MLMultiArray? = nil
    lazy var actModel:CreateMLActivity = {
        do{
            let config = MLModelConfiguration()
            return try CreateMLActivity(configuration: config)
        }catch{
            print(error)
            fatalError("Could not load custom model")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        startMotionUpdates()
    }

    @IBAction func magnitudeChanged(_ sender: UISlider) {
        self.magValue = Double(sender.value)
    }
    
 

}

//MARK: Local ML Model
extension CMLViewController{
    
    func setDelayedWaitingToTrue(_ time:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
            self.isWaitingForMotionData = true
        })
    }
    
    func largeMotionEventOccurred(){
        
        if(self.isWaitingForMotionData)
        {
            self.isWaitingForMotionData = false
            
            let seq = self.ringBuffer.getDataAsVector()
            
            guard var stateIn = try? MLMultiArray(shape:[400], dataType:MLMultiArrayDataType.double) else {
                fatalError("Unexpected runtime error. MLMultiArray could not be created")
            }
            
            // if we have a state from the classifier, provide it
            if let state = stateOut{
                
                // if we trained the ML Model classify longer sequences, this might be important. However we trained the example using 50 isolated samples, so we should not provide anythin here.
                //stateIn = state
            }
            
            let tmp = CreateMLActivityInput(x: seq.x,
                                            y: seq.y,
                                            z: seq.z,
                                            stateIn: stateIn)
            
            //predict a label
            guard let outputTuri = try? actModel.prediction(input: tmp) else {
                fatalError("Unexpected runtime error.")
            }
            // remember this state for the future
            stateOut = outputTuri.stateOut

            displayLabelResponse(outputTuri.label)
            
            // only provide another label after 2 seconds
            setDelayedWaitingToTrue(2.0)
        }
    }
    
    
}


// MARK: Core Motion Updates
extension CMLViewController {
    
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200
            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let accel = motionData?.userAcceleration {
            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
            let mag = fabs(accel.x)+fabs(accel.y)+fabs(accel.z)
            
            DispatchQueue.main.async{
                //show magnitude via indicator
                self.largeMotionMagnitude.progress = Float(mag)/0.2
            }
            
            if mag > self.magValue {
                // buffer up a bit more data and then notify of occurrence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                    // something large enough happened to warrant
                    self.largeMotionEventOccurred()
                })
            }
        }
    }
    
}


//MARK: UI Label Updates
extension CMLViewController{
    func setAsCalibrating(_ label: UILabel){
        label.layer.add(animation, forKey:nil)
        label.backgroundColor = UIColor.red
    }
    
    func setAsNormal(_ label: UILabel){
        label.layer.add(animation, forKey:nil)
        label.backgroundColor = UIColor.white
    }
    
    
    
    
    func displayLabelResponse(_ response:String){
        switch response {
        case "up":
            blinkLabel(upArrow)
            break
        case "down":
            blinkLabel(downArrow)
            break
        case "left":
            blinkLabel(leftArrow)
            break
        case "right":
            blinkLabel(rightArrow)
            break
        default:
            print("Unknown")
            break
        }
    }
    
    func blinkLabel(_ label:UILabel){
        DispatchQueue.main.async {
            self.setAsCalibrating(label)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.setAsNormal(label)
            })
        }
        
    }
}
