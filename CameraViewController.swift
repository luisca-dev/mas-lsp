import UIKit
import AVFoundation
import Vision
import SwiftUI

// Wrapper para usar UIViewController en SwiftUI
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var poseDetector: PoseDetector

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.poseDetector = poseDetector
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoDataOutput = AVCaptureVideoDataOutput()

    var poseDetector: PoseDetector?

    // Capas para dibujar
    private var handOverlayLayer = CAShapeLayer()
    private var bodyOverlayLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        handOverlayLayer.frame = view.bounds
        bodyOverlayLayer.frame = view.bounds
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
        // Configuración Capa Manos
        handOverlayLayer.fillColor = UIColor.clear.cgColor
        handOverlayLayer.strokeColor = UIColor.green.cgColor
        handOverlayLayer.lineWidth = 3
        view.layer.addSublayer(handOverlayLayer)

        // Configuración Capa Cuerpo
        bodyOverlayLayer.fillColor = UIColor.clear.cgColor
        bodyOverlayLayer.strokeColor = UIColor.blue.cgColor
        bodyOverlayLayer.lineWidth = 5 // Más grueso para el cuerpo
        view.layer.addSublayer(bodyOverlayLayer)
    }

    func drawPose(poseData: PoseData) {
        drawPoints(poseData.handPoints, on: handOverlayLayer)
        drawPoints(poseData.bodyPoints, on: bodyOverlayLayer)
    }

    private func drawPoints(_ points: [CGPoint], on layer: CAShapeLayer) {
        let path = UIBezierPath()

        for point in points {
            // Convertir coordenadas normalizadas a coordenadas de la vista
            let x = point.x * view.bounds.width
            let y = (1 - point.y) * view.bounds.height // Invertir Y

            let circlePath = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            path.append(circlePath)
        }

        layer.path = path.cgPath
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Llamar al detector
        poseDetector?.processFrame(pixelBuffer: pixelBuffer) { [weak self] poseData in
            DispatchQueue.main.async {
                self?.drawPose(poseData: poseData)
            }
        }
    }
}
