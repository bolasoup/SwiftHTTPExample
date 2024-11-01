//
//  RingBuffer.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson 
//  Copyright © 2024 Eric Larson. All rights reserved.
//

import UIKit
import CoreML

let BUFFER_SIZE = 50

class RingBuffer: NSObject {
    
    var x = [Double](repeating:0, count:BUFFER_SIZE)
    var y = [Double](repeating:0, count:BUFFER_SIZE)
    var z = [Double](repeating:0, count:BUFFER_SIZE)
    
    var head:Int = 0 {
        didSet{
            if(head >= BUFFER_SIZE){
                head = 0
            }
            
        }
    }
    
    func addNewData(xData:Double,yData:Double,zData:Double){
        x[head] = xData
        y[head] = yData
        z[head] = zData
        
        head += 1
    }
    
    func getDataAsVector()->(x:MLMultiArray,y:MLMultiArray,z:MLMultiArray){
        var x_data = [Double](repeating:0, count:BUFFER_SIZE)
        var y_data = [Double](repeating:0, count:BUFFER_SIZE)
        var z_data = [Double](repeating:0, count:BUFFER_SIZE)
        
        for i in 0..<BUFFER_SIZE {
            let idx = (head+i)%BUFFER_SIZE
            x_data[i] = x[idx]
            y_data[i] = y[idx]
            z_data[i] = z[idx]
        }
        
        return (toMLMultiArray(x_data),toMLMultiArray(y_data),toMLMultiArray(z_data))
    }
    
    // convert to ML Multi array
    // https://github.com/akimach/GestureAI-CoreML-iOS/blob/master/GestureAI/GestureViewController.swift
    private func toMLMultiArray(_ arr: [Double]) -> MLMultiArray {
        // create an empty multi array
        guard let sequence = try? MLMultiArray(shape:[50], dataType:MLMultiArrayDataType.double) else {
            fatalError("Unexpected runtime error. MLMultiArray could not be created")
        }
        
        // populate the multi array with data
        let size = Int(truncating: sequence.shape[0])
        for i in 0..<size {
            sequence[i] = NSNumber(floatLiteral: arr[i])
        }
        return sequence
    }

}
