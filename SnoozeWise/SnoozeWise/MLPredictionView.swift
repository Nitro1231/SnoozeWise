//
//  MLPredictionView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/27/24.
//

import SwiftUI
import CoreML

struct MLPredictionView: View {
    
    @State private var model: sleepCoreML? = nil
    @State private var inputArray: sleepCoreMLInput? = nil

    
    var body: some View {
        VStack {
            Text("Core ML Model Integration")
                .font(.title)
                .padding()
            
            Button("Make Prediction") {
                do {
                    let output = try self.model!.prediction(input: self.inputArray!)
                    
                    let outputArray: MLMultiArray = output.linear_13
                    print("Model output: \(outputArray)")
                } catch {
                    print("Error making prediction: \(error.localizedDescription)")
                }
            }
            .padding()
        }
        .onAppear {
            self.loadModel()
            self.initializeInputArray()
        }
    }
    
    private func initializeInputArray() {
        do {
            let inputShape: [NSNumber] = [NSNumber(value: 128), NSNumber(value: 2)]
            self.inputArray = try sleepCoreMLInput(src_1: MLMultiArray(shape: inputShape, dataType: .float32))
        } catch {
            print("Error initializing input array: \(error.localizedDescription)")
        }
    }
    
    private func loadModel() {
        do {
            self.model = try sleepCoreML()
        } catch {
            print("Error initializing model: \(error.localizedDescription)")
        }
    }
}

