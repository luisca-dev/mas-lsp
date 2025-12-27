import SwiftUI

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var handPoseDetector = HandPoseDetector()
    @State private var mode: AppMode = .listening

    enum AppMode {
        case listening // Voz a Texto
        case signing   // Señas a Voz
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MAS Intérprete")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Picker("Modo", selection: $mode) {
                    Text("Escuchar").tag(AppMode.listening)
                    Text("Interpretar").tag(AppMode.signing)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding()
            .background(Color.blue)

            if mode == .listening {
                // Modo: Oído (Persona sorda lee lo que le dicen)
                VStack {
                    Spacer()
                    ScrollView {
                        Text(speechRecognizer.transcript)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    Spacer()

                    Button(action: {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopRecording()
                        } else {
                            speechRecognizer.startRecording()
                        }
                    }) {
                        Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
                    }
                    .padding(.bottom, 50)
                }
            } else {
                // Modo: Ojo (Persona oyente ve traducción de señas)
                ZStack {
                    CameraView(handPoseDetector: handPoseDetector)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        Spacer()
                        HStack {
                            Text("Traducción: ")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)

                            Text(handPoseDetector.detectedSign)
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.yellow)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
        }
    }
}
