import Foundation
import Vision
import AppKit

class OCRManager {
    static func performOCR(on image: NSImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let tiffData = image.tiffRepresentation,
              let imageSource = CGImageSourceCreateWithData(tiffData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            completion(.failure(NSError(domain: "OCRManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to CGImage."])))
            return
        }
        
        // Setup Vision text recognition request
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "OCRManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text found in screenshot."])))
                return
            }
            
            var recognizedText = ""
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                recognizedText += candidate.string + "\n"
            }
            
            recognizedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(.success(recognizedText))
        }
        
        // Use high accuracy mode (Vision will run slower but highly precise)
        request.recognitionLevel = .accurate
        // Prioritize English and Polish, fallback to system languages
        request.recognitionLanguages = ["en-US", "pl-PL", "de-DE", "es-ES", "fr-FR"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Run in background queue to keep the UI smooth
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
}
