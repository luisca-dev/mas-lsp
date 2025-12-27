import UIKit
import AVFoundation
import Vision
import SwiftUI

// Wrapper para usar UIViewController en SwiftUI
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var handPoseDetector: HandPoseDetector

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.handPoseDetector = handPoseDetector
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoDataOutput = AVCaptureVideoDataOutput()

    var handPoseDetector: HandPoseDetector?

    // Capas para dibujar el esqueleto de la mano
    private var overlayLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        overlayLayer.frame = view.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Usar cámara frontal
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("No se pudo acceder a la cámara frontal")
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(videoDataOutput) {
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            session.addOutput(videoDataOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func setupOverlay() {
        overlayLayer.fillColor = UIColor.clear.cgColor
        overlayLayer.strokeColor = UIColor.green.cgColor
        overlayLayer.lineWidth = 3
        view.layer.addSublayer(overlayLayer)
    }

    func drawHandPoints(points: [CGPoint]) {
        let path = UIBezierPath()

        for point in points {
            // Convertir coordenadas normalizadas a coordenadas de la vista
            let x = point.x * view.bounds.width
            let y = (1 - point.y) * view.bounds.height // Invertir Y porque Vision usa coordenadas normalizadas con origen abajo-izquierda

            let circlePath = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            path.append(circlePath)
        }

        overlayLayer.path = path.cgPath
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Llamar al detector de manos
        handPoseDetector?.processFrame(pixelBuffer: pixelBuffer) { [weak self] points in
            DispatchQueue.main.async {
                self?.drawHandPoints(points: points)
            }
        }
    }
}
