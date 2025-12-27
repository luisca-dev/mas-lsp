# MAS Intérprete (Ministerio de Sordos - IASD)

## "Más inclusión, más amor, más conexión."

Este proyecto es un prototipo de una aplicación para iPad diseñada para facilitar la comunicación bidireccional entre personas sordas y oyentes.

### Funcionalidades
1.  **Voz a Señas (Oído -> Ojo):**
    - Escucha lo que dice una persona oyente mediante el micrófono.
    - Transcribe el texto en pantalla grande para que la persona sorda pueda leerlo.
    - (Futuro) Un avatar interpretará el texto a Lengua de Señas Peruana (LSP).

2.  **Señas a Voz (Ojo -> Oído):**
    - Utiliza la cámara frontal para detectar las manos de la persona sorda.
    - Utiliza `Vision` framework para identificar la pose de las manos.
    - (Prototipo) Muestra visualmente que la aplicación está "viendo" las manos y simula una interpretación básica.

### Cómo usar en Swift Playgrounds
1.  Crea un nuevo proyecto de "App" en Swift Playgrounds en tu iPad.
2.  Copia el contenido de los archivos `.swift` proporcionados en este repositorio a tu proyecto.
    - `MyApp.swift` (Punto de entrada)
    - `ContentView.swift` (Interfaz)
    - `SpeechRecognizer.swift` (Lógica de audio)
    - `CameraViewController.swift` (Cámara)
    - `HandPoseDetector.swift` (Visión)
3.  Ejecuta la app. Deberás otorgar permisos de **Cámara** y **Reconocimiento de Voz**.
