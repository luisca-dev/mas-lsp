import Foundation
import Vision
import CoreMedia
import UIKit
import AVFoundation

class HandPoseDetector: ObservableObject {
    @Published var detectedSign: String = "..."

    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpokenSign: String = ""
    private var lastDetectionTime: Date = Date()

    func processFrame(pixelBuffer: CVPixelBuffer, completion: @escaping ([CGPoint]) -> Void) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])

        do {
            try handler.perform([handPoseRequest])

            guard let observation = handPoseRequest.results?.first else {
                DispatchQueue.main.async {
                    self.detectedSign = "..."
                }
                completion([])
                return
            }

            // Obtener todos los puntos de la mano
            let points = try observation.recognizedPoints(.all)

            // Convertir a un array de CGPoints para dibujar
            let cgPoints = points.values.map { CGPoint(x: $0.x, y: $0.y) }

            // Análisis simple de gestos (Lógica simulada)
            analyzeGesture(points: points)

            completion(cgPoints)

        } catch {
            print("Error detectando mano: \(error)")
            completion([])
        }
    }

    private func analyzeGesture(points: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) {
        guard let thumbTip = points[.thumbTip],
              let indexTip = points[.indexTip],
              let middleTip = points[.middleTip],
              let ringTip = points[.ringTip],
              let littleTip = points[.littleTip],
              let wrist = points[.wrist] else {
            return
        }

        // Detección muy básica basada en la posición de la punta de los dedos vs la muñeca
        let fingersUp = [thumbTip, indexTip, middleTip, ringTip, littleTip].filter { $0.y > wrist.y }.count

        var currentSign = ""

        if fingersUp >= 4 {
            currentSign = "Hola"
        } else if fingersUp == 0 || fingersUp == 1 {
            currentSign = "Sí" // Asumiendo puño cerrado como "Sí" o "S"
        } else if fingersUp == 2 {
            currentSign = "Victoria"
        } else {
            currentSign = "..."
        }

        DispatchQueue.main.async {
            self.detectedSign = currentSign
            self.speakIfNeeded(text: currentSign)
        }
    }

    private func speakIfNeeded(text: String) {
        // Evitar hablar si es el mismo texto o si es "..."
        guard text != "..." && text != lastSpokenSign else { return }

        // Evitar hablar demasiado rápido (debounce simple de 2 segundos)
        guard Date().timeIntervalSince(lastDetectionTime) > 2.0 else { return }

        lastSpokenSign = text
        lastDetectionTime = Date()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-PE")
        speechSynthesizer.speak(utterance)
    }
}
