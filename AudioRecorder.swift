import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    var isRecording: Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    override init() {
        super.init()
        let tempDirectory = FileManager.default.temporaryDirectory
        recordingURL = tempDirectory.appendingPathComponent("whisper_mic_recording.m4a")
    }
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func startRecording() -> Bool {
        guard let url = recordingURL else { return false }
        
        // Settings optimized for Whisper (16kHz sample rate, mono)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            return audioRecorder?.record() ?? false
        } catch {
            print("Failed to setup audio recorder: \(error)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        return recordingURL
    }
}
