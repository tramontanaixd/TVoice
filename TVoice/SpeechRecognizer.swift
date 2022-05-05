//
//  SpeechRecognizer.swift
//  TVoice
//
//  Created by local on 1/23/22.
//
import AVFoundation
import Foundation
import Speech
import UIKit

class SpeechRecognizer: NSObject {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    var transcript: String = ""
    
    private var audioEngine: AVAudioEngine! = AVAudioEngine();
    private var request: SFSpeechAudioBufferRecognitionRequest! = SFSpeechAudioBufferRecognitionRequest();
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    override init() {
        recognizer = SFSpeechRecognizer();
        super.init();
        
        requestSpeechAuthorization();
      
    }
    private func requestSpeechAuthorization() {
            SFSpeechRecognizer.requestAuthorization { (authStatus) in
                OperationQueue.main.addOperation {
                    switch authStatus {
                    case .authorized:
                        print("authorized")
                    case .denied:
                        
                        print("denied")
                        NotificationCenter.default.post(name: NSNotification.Name("denied"), object: nil);
                    case .restricted:
                        print("restricted")
                    case .notDetermined:
                        print("notDeterminded")
                    }
                }
            }
        }
    
    deinit {
        reset()
    }
    
    func recordAndRecognizeSpeech(delegate:SFSpeechRecognitionTaskDelegate) {
        request = SFSpeechAudioBufferRecognitionRequest();
        audioEngine = AVAudioEngine();
        let node = audioEngine.inputNode
            let recordingFormat = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
                self.request.append(buffer)
            }
            
        audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                return print(error)
            }
            
            guard let myRecognizer = SFSpeechRecognizer() else {
                print("A recognizer is not supported for the current locale")
                return
            }
            if !myRecognizer.isAvailable {
                print("A recognizer is not available right now")
                return
            }
            
        task = recognizer?.recognitionTask(with: request, delegate: delegate)
        }
    
    func stopTranscribing() {
        reset()
    }
    
    func reset() {
        task?.cancel()
        audioEngine.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
   
}


