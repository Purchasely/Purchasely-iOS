//
//  QRCodeScanner.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 07/05/2025.
//

import SwiftUI
import AVFoundation // Import AVFoundation for camera and metadata operations

// MARK: - QR Code Scanner View (UIViewControllerRepresentable)

/// A SwiftUI view that wraps a UIViewController to handle QR code scanning.
struct QRCodeScannerView: UIViewControllerRepresentable {
    /// Binding to the scanned code string. Updated when a QR code is successfully scanned.
    @Binding var scannedCode: String?

    /// Coordinator class to handle AVCaptureMetadataOutputObjectsDelegate methods.
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView

        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }

        /// This delegate method is called when the capture output object detects new metadata objects.
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            // Check if a QR code was found
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }

                // A QR code was successfully scanned.
                // Update the parent view's state.
                // Ensure UI updates are on the main thread.
                DispatchQueue.main.async {
                    self.parent.scannedCode = stringValue
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
            }
        }
    }

    /// Creates the Coordinator instance.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Creates and configures the UIViewController that hosts the camera view.
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let viewController = QRCodeScannerViewController()
        viewController.delegate = context.coordinator // Set the coordinator as the delegate
        return viewController
    }

    /// Updates the UIViewController (not typically needed for this static view).
    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        // No updates needed from SwiftUI to the ViewController in this case
    }
}

// MARK: - QR Code Scanner UIViewController

/// UIViewController subclass that manages the AVCaptureSession for QR code scanning.
class QRCodeScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black // Set background color

        // 1. Initialize AVCaptureSession
        captureSession = AVCaptureSession()

        // 2. Get the default video capture device (camera)
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            handleError("Failed to get the camera device.")
            return
        }

        // 3. Create an AVCaptureDeviceInput from the video capture device
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            handleError("Failed to create video input: \(error.localizedDescription)")
            return
        }

        // 4. Add the video input to the capture session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            handleError("Could not add video input to the session.")
            return
        }

        // 5. Create an AVCaptureMetadataOutput object and add it to the session
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            // 6. Set the delegate and dispatch queue for metadata output
            //    The queue must be serial to ensure metadata objects are delivered in order.
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            // 7. Specify the types of metadata objects to detect (QR codes in this case)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            handleError("Could not add metadata output to the session.")
            return
        }

        // 8. Create a preview layer to display the camera feed
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // 9. Start the capture session (on a background thread to avoid blocking UI)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure session is running when the view appears
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop session when the view disappears to save resources
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the preview layer's frame is updated if the view's bounds change (e.g., rotation)
        previewLayer?.frame = view.layer.bounds
    }

    /// Helper function to handle errors and inform the delegate (parent SwiftUI view).
    private func handleError(_ message: String) {
        print("QR Scanner Error: \(message)")
        // Use the delegate's parent to show an alert in SwiftUI
        if let coordinator = delegate as? QRCodeScannerView.Coordinator { }
    }
}
