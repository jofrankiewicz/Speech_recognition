//
//  ViewController.swift
//  Speech Recognition
//
//  Created by Joanna Frankiewicz on 28/02/2019.
//  Copyright © 2019 Joanna Frankiewicz. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate{

    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var ESButton: UIButton!
    @IBOutlet weak var DEButton: UIButton!
    @IBOutlet weak var ITButton: UIButton!
    @IBOutlet weak var FRButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US")) //Say something in english!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? //manage audio buffor and send it in time during user's speech
    private var recognitionTask: SFSpeechRecognitionTask? //recognition speech
    private let audioEngine = AVAudioEngine() //processing audio input
    var lang: String = "en-US"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startStopButton.isEnabled = false
        speechRecognizer?.delegate = self
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false //can we use our button?
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.startStopButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    @IBAction func StartStopRecording(_ sender: AnyObject) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        let record = UIImage(named: "mikrofon.jpg") //nagrywaj
        let stop = UIImage(named: "stop.png")
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startStopButton.isEnabled = false
            startStopButton.setImage(record, for: .normal)
        } else {
            startRecording()
            startStopButton.setImage(stop, for: .normal)
        }
    }
    
    func startRecording() { //record new words
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startStopButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        textView.text = "Say something, I'm listening!"
    }
    

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startStopButton.isEnabled = true
        } else {
            startStopButton.isEnabled = false
        }
    }
    

}

