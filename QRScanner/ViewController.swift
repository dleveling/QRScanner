//
//  ViewController.swift
//  QRScanner
//
//  Created by Ice on 26/3/2562 BE.
//  Copyright © 2562 Ice. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRScannerPermissionViewControllerDelegate: class {
    func dismissPermissionView(_ qrScannerPermissionViewController: ViewController)
    func cameraPermissionGranted(_ qrScannerPermissionViewController: ViewController)
}

class ViewController: UIViewController {
    
    weak var delegate: QRScannerPermissionViewControllerDelegate?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureSession?
    private var detectedString: String?
    
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performAllowAction()
        setupCameraView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    
    ///Ask for access the camera
    private func performAllowAction() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            // If the user has not yet been asked for camera access, ask for permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let strongSelf = self else { return }
                if granted {
                    DispatchQueue.main.async {
                        strongSelf.delegate?.cameraPermissionGranted(strongSelf)
                    }
                }
            }
            
        } else if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            // If the user has previously denied access, go to app's settings
            if let url = URL(string:UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }

    func setupCameraView(){

        let captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            codeLabel.text = "Fail Scanning"
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
            
        } else {
            codeLabel.text = "Fail Scanning"
            return
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.frame = cameraView.layer.bounds
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        if let videoPreviewLayer = videoPreviewLayer {
            cameraView.layer.addSublayer(videoPreviewLayer)
        }
        
        self.captureSession = captureSession
        
    }
 
    func startScanning(){
        captureSession?.startRunning()
    }
    
    func stopScanning(){
        captureSession?.stopRunning()
    }
    
    @IBAction func scanAgain(_ sender: UIButton) {
        startScanning()
        codeLabel.text = ""
    }
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        stopScanning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            detectedString = stringValue
            codeLabel.text = detectedString
        }
    }
}
