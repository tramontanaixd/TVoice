//
//  ViewController.swift
//  TVoice
//
//  Created by local on 1/22/22.
//

import UIKit
import Speech
import Foundation
import Telegraph
import JavaScriptCore



class ViewController: UIViewController  {

    @IBOutlet var startButton:UIButton!;
    @IBOutlet var textField:UITextView!;
    @IBOutlet var stopButton:UIButton!;
    @IBOutlet var ipLabel:UILabel?;
    
    let NOTREC:Int = 0;
    let REC:Int = 1;
    
    var state:Int = 0;
    
    var speechRecognizer = SpeechRecognizer();
    let networkManager = NetworkManager.shared;
    
    //MANAGE RECOGNIZED STRING AND SEND
    var checkTag:Float = -1.0;
    var stringSent:String = "";
    var keepTrack:Double = 1.0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        networkManager.setupServer(_newPort: 8072, _newDelegate: self);
        
        checkForIp();
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("denied"), object: nil, queue: OperationQueue.main) { [self] notification in
            self.startButton.alpha = 0;
            textField.text = "Without authorization for microphone and speech recognition this app is pretty useless. You can fix this by going to settings";
        }
       
    }
    private func checkForIp()
    {
        guard let wifiIp = getAddress(for: .wifi) else {
            ipLabel?.text = "error";
            
            return }
        ipLabel?.text = wifiIp+":\(networkManager.port)";
        var _ = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            self.checkForIp();
        };
    }
    @IBAction func startRecognizer()
    {
        speechRecognizer.recordAndRecognizeSpeech(delegate:self);
        UIView.animate(withDuration: 0.2) {
            self.stopButton.alpha = 1.0;
            self.startButton.alpha = 0.0;
        };
        
    }
    @IBAction func stopRecognizer()
    {
        speechRecognizer.reset();
        UIView.animate(withDuration: 0.2) {
            self.stopButton.alpha = 0.0;
            self.startButton.alpha = 1.0;
        };
        self.stringSent = "";
    }


}
extension ViewController:SFSpeechRecognitionTaskDelegate{
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        var bestString = transcription.formattedString

        var lastString = "";

//        }
        textField.text = bestString;
        
        
        self.keepTrack = Date.currentTimeStamp;
        
        var _ = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [self] t in
            
            print(Date.currentTimeStamp-self.keepTrack);
            if(Date.currentTimeStamp-self.keepTrack>0.6)
            {
                //make difference between full transcript and just latest string.
            
                if(self.stringSent == "")
                {
                    self.stringSent = bestString;
                    networkManager.broadcast(message: self.stringSent );
                }
                else
                {
                    let context = JSContext()!
                    context.evaluateScript(#"""
                        function splitString(fullString,sentString) {
                            
                            let index = fullString.lastIndexOf(sentString);
                                                        
                           return fullString.substring(index+sentString.length,fullString.length);
                            
                        }
                        """#);
                    let splitString = context.objectForKeyedSubscript("splitString")!
                    
                    let result = splitString.call(withArguments: [bestString,self.stringSent])!.toString()
                    self.stringSent += result!;
                    print(result);
                    networkManager.broadcast(message: result!);
                }
            }
        }
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        task.finish()
        print("finish");
    }
    
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        print("finished recording audio.")
        
    }
}
extension ViewController:ServerWebSocketDelegate{
    func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest){
        print("socket did connect");
        networkManager.addClient(socket: webSocket);
    }
    
    func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?)
    {
        print("socket did disconnect");
        networkManager.removeClient(socket: webSocket);
    }

    /// Called when a message was received from a web socket
    func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage){
        
    }

    /// Called when a message was sent to a web socket
    func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage){
        
    }
}

extension Date{
    static var currentTimeStamp:Double{
        return Double(Date().timeIntervalSince1970);
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}
