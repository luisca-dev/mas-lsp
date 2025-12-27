import Foundation
import Vision
import CoreMedia
import UIKit
import AVFoundation

struct PoseData {
    var bodyPoints: [CGPoint]
    var handPoints: [CGPoint]
}

class PoseDetector: ObservableObject {
    @Published var detectedSign: String = "..."

    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpokenSign: String = ""
    private var lastDetectionTime: Date = Date()

    init() {
        handPoseRequest.maximumHandCount = 2
    }

    func processFrame(pixelBuffer: CVPixelBuffer, completion: @escaping (PoseData) -> Void) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])

        do {
            try handler.perform([handPoseRequest, bodyPoseRequest])

            // Procesar Manos
            var allHandPoints: [CGPoint] = []
            var allHandObservations: [VNHumanHandPoseObservation] = []

            if let handResults = handPoseRequest.results {
                allHandObservations = handResults
                for observation in handResults {
                    let points = try observation.recognizedPoints(.all)
                    let cgPoints = points.values.map { CGPoint(x: $0.x, y: $0.y) }
                    allHandPoints.append(contentsOf: cgPoints)
                }
            }

            // Procesar Cuerpo
            var allBodyPoints: [CGPoint] = []
            var bodyObservation: VNHumanBodyPoseObservation?

            if let bodyResult = bodyPoseRequest.results?.first {
                bodyObservation = bodyResult
                let points = try bodyResult.recognizedPoints(.all)
                let cgPoints = points.values.map { CGPoint(x: $0.x, y: $0.y) }
                allBodyPoints.append(contentsOf: cgPoints)
            }

            // Análisis Combinado
            analyzePose(hands: allHandObservations, body: bodyObservation)

            let poseData = PoseData(bodyPoints: allBodyPoints, handPoints: allHandPoints)
            completion(poseData)

        } catch {
            print("Error detectando pose: \(error)")
            completion(PoseData(bodyPoints: [], handPoints: []))
        }
    }

    private func analyzePose(hands: [VNHumanHandPoseObservation], body: VNHumanBodyPoseObservation?) {
        // Lógica Heurística Avanzada (Cuerpo + Manos)
        var currentSign = "..."

        // Necesitamos puntos del cuerpo para contexto
        guard let body = body,
              let leftShoulder = try? body.recognizedPoint(.leftShoulder),
              let rightShoulder = try? body.recognizedPoint(.rightShoulder),
              leftShoulder.confidence > 0.3, rightShoulder.confidence > 0.3 else {
            // Si no vemos hombros claramente, fallback a lógica simple o nada
            return
        }

        // Detectar "Manos Arriba" (Ambas muñecas por encima de los hombros)
        // Nota: En Vision Y=0 es abajo, Y=1 es arriba. Por lo tanto, Arriba > Hombros

        var handsAboveShoulders = 0

        for hand in hands {
            if let wrist = try? hand.recognizedPoint(.wrist), wrist.confidence > 0.3 {
                // Compara con el hombro promedio altura (aproximación)
                let shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2.0
                if wrist.y > shoulderHeight {
                    handsAboveShoulders += 1
                }
            }
        }

        if handsAboveShoulders >= 2 {
            currentSign = "¡Aleluya! / Manos Arriba"
        } else {
             // Lógica de dedos individual (si no es manos arriba)
             // Tomamos la primera mano detectada para gestos simples
             if let primaryHand = hands.first {
                 currentSign = analyzeHandGesture(points: try? primaryHand.recognizedPoints(.all))
             }
        }

        DispatchQueue.main.async {
            if currentSign != "..." {
                self.detectedSign = currentSign
                self.speakIfNeeded(text: currentSign)
            } else {
                // Solo limpiar si llevamos un rato sin detectar nada
                if Date().timeIntervalSince(self.lastDetectionTime) > 1.0 {
                    self.detectedSign = "..."
                }
            }
        }
    }

    private func analyzeHandGesture(points: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]?) -> String {
        guard let points = points,
              let thumbTip = points[.thumbTip],
              let indexTip = points[.indexTip],
              let middleTip = points[.middleTip],
              let ringTip = points[.ringTip],
              let littleTip = points[.littleTip],
              let wrist = points[.wrist] else {
            return "..."
        }

        let fingersUp = [thumbTip, indexTip, middleTip, ringTip, littleTip].filter { $0.y > wrist.y }.count

        if fingersUp >= 4 {
            return "Hola"
        } else if fingersUp == 0 || fingersUp == 1 {
            return "Sí"
        } else if fingersUp == 2 {
            return "Victoria"
        }
        return "..."
    }

    private func speakIfNeeded(text: String) {
        guard text != "..." && text != lastSpokenSign else { return }
        guard Date().timeIntervalSince(lastDetectionTime) > 2.0 else { return }

        lastSpokenSign = text
        lastDetectionTime = Date()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-PE")
        speechSynthesizer.speak(utterance)
    }
}
