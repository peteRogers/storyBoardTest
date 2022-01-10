//
//  CameraVC.swift
//  storyBoardTest
//
//  Created by dt on 10/01/2022.
//

import UIKit
import AVFoundation
import Vision

class CameraVC: UIViewController,  AVCaptureVideoDataOutputSampleBufferDelegate
{
    var visionToAVFTransform = CGAffineTransform.identity
    var request: VNDetectHumanRectanglesRequest!
    private let captureSession = AVCaptureSession()
       private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
           let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
           preview.videoGravity = .resizeAspect
           return preview
       }()
       private let videoOutput = AVCaptureVideoDataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        request = VNDetectHumanRectanglesRequest(completionHandler: recognizeHumans)
        self.addCameraInput()
               self.addPreviewLayer()
               self.addVideoOutput()
               self.captureSession.startRunning()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           self.previewLayer.frame = self.view.bounds
       }
    
    
    
     func recognizeHumans(request:VNRequest, error: Error?){
         
         var redBoxes = [CGRect]()
         guard let results = request.results as? [VNHumanObservation] else {
             return
         }
         
     
         for result in results{
            print(result.boundingBox.minX)
             redBoxes.append(result.boundingBox)
             show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes)])
             
         }
     }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewLayer
            self.removeBoxes()
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
    
    // Draw a box on screen. Must be called from main queue.
        var boxLayer = [CAShapeLayer]()
        func draw(rect: CGRect, color: CGColor) {
            let layer = CAShapeLayer()
            layer.opacity = 1
            layer.borderColor = color
            layer.borderWidth = 2.5
            layer.frame = rect
            boxLayer.append(layer)
            self.previewLayer.insertSublayer(layer, at: 1)
        }
        
        // Remove all drawn boxes. Must be called on main queue.
        func removeBoxes() {
            for layer in boxLayer {
                layer.removeFromSuperlayer()
            }
            boxLayer.removeAll()
        }
    
    func captureOutput(_ output: AVCaptureOutput,
                         didOutput sampleBuffer: CMSampleBuffer,
                         from connection: AVCaptureConnection) {
          guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
              debugPrint("unable to get image from sample buffer")
              return
          }
          print("did receive image frame")
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: frame, orientation: .up, options: [:])
                    do {
                        try requestHandler.perform([request])
                    } catch {
                        print(error)
                    }
          // process image here
      }

      private func addCameraInput() {
          let device = AVCaptureDevice.default(for: .video)!
          let cameraInput = try! AVCaptureDeviceInput(device: device)
          self.captureSession.addInput(cameraInput)
      }
      
      private func addPreviewLayer() {
          self.view.layer.addSublayer(self.previewLayer)
      }
      
      private func addVideoOutput() {
          self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
          self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
          self.captureSession.addOutput(self.videoOutput)
      }
   

}
