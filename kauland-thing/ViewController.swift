//
//  ViewController.swift
//  kauland-thing
//
//  Created by Joe Lao on 17/11/2018.
//  Copyright © 2018 Joe Lao. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {

    let products = [
        4001686301265:"haribo",
        4300175162883:"cherries",
        4300175162920:"appricots",
        4337185077241:"energy drink",
        4337185153013:"choco cereals",
        4337185240386:"corn flakes",
        4337185276682:"peaches",
        4337185303739:"choc IT",
        4337185373619:"chips",
        4337185396243:"flour weizen",
        4337185396748:"sugar",
        4337185558740:"canned pears"
    ]
    
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCaptureSession()
        view.addSubview(label)
        setupLabel()
    }

    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        // create a new capture session
        let captureSession = AVCaptureSession()
        
        // find the available cameras
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        do {
            // select a camera
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
            
        } catch {
            // print an error if the camera is not available
            print(error.localizedDescription)
        }
        
        // setup the video output to the screen and add output to our capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        // barcode delegate
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "videoQueue1"))
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.code128]
        
        // buffer the video and start the capture session
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue2"))
        captureSession.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        // load our CoreML model
        guard let model = try? VNCoreMLModel(for: identifier_5().model) else { return }
        
        // run an inference with CoreML
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            
            // grab the inference results
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            
            // grab the highest confidence result
            guard let Observation = results.first else { return }
            
            // create the label text components
            let predclass = "\(Observation.identifier)"
            let predconfidence = String(format: "%.02f%", Observation.confidence * 100)
            
            // set the label text
            DispatchQueue.main.async(execute: {
                self.label.text = "\(predclass) \(predconfidence)"
            })
        }
        
        // create a Core Video pixel buffer which is an image buffer that holds pixels in main memory
        // Applications generating frames, compressing or decompressing video, or using Core Image
        // can all make use of Core Video pixel buffers
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func resizeBuffer(buffer: CMSampleBuffer) -> CVPixelBuffer? {
        let imgBuf = CMSampleBufferGetImageBuffer(buffer)
        let image = CIImage(cvImageBuffer: imgBuf!)
        let width = image.cgImage!.width
        let height = image.cgImage!.height
        let resized: CIImage
        if width < height {
            resized = image.transformed(by: CGAffineTransform(scaleX: 1, y: CGFloat(width/height)))
        } else {
            resized = image.transformed(by: CGAffineTransform(scaleX: CGFloat(height/width), y: 1))
        }
        
        return resized.pixelBuffer
        
    }
    
    func setupLabel() {
        // constrain the label in the center
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        // constrain the the label to 50 pixels from the bottom
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }


}

