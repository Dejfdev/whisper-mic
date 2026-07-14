import Foundation

class OpenAIClient {
    enum ClientError: Error {
        case missingApiKey
        case invalidResponse
        case apiError(String)
    }
    
    func transcribe(fileURL: URL, language: String?, prompt: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = KeychainHelper.load(), !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.failure(ClientError.missingApiKey))
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Helper to append form fields
        func appendField(name: String, value: String) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add required model parameter
        appendField(name: "model", value: "whisper-1")
        
        // Add language if specified
        if let language = language, !language.isEmpty, language != "auto" {
            appendField(name: "language", value: language)
        }
        
        // Add prompt if specified (used to guide formatting, punctuation, etc.)
        if let prompt = prompt, !prompt.isEmpty {
            appendField(name: "prompt", value: prompt)
        }
        
        // Add audio file
        do {
            let fileData = try Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent
            let mimeType = "audio/m4a"
            
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Add closing boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 60.0
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(ClientError.invalidResponse))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let text = json["text"] as? String {
                        completion(.success(text))
                    } else if let errorDict = json["error"] as? [String: Any], let message = errorDict["message"] as? String {
                        completion(.failure(ClientError.apiError(message)))
                    } else {
                        completion(.failure(ClientError.invalidResponse))
                    }
                } else {
                    completion(.failure(ClientError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // A quick check to test connection validity
    func testConnection(apiKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/models/whisper-1")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ClientError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 200 {
                completion(.success(()))
            } else {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorDict = json["error"] as? [String: Any],
                   let message = errorDict["message"] as? String {
                    completion(.failure(ClientError.apiError(message)))
                } else {
                    completion(.failure(ClientError.apiError("API key validation failed (Status \(httpResponse.statusCode)).")))
                }
            }
        }.resume()
    }
}

extension OpenAIClient.ClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "OpenAI API Key is missing. Please add it in Preferences."
        case .invalidResponse:
            return "Received invalid response from OpenAI."
        case .apiError(let message):
            return message
        }
    }
}
