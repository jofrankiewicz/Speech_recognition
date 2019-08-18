//
//  ViewController.swift
//  Speech Recognition
//
//  Created by Joanna Frankiewicz on 28/02/2019.
//  Copyright © 2019 Joanna Frankiewicz. All rights reserved.
//

import UIKit
import Speech
import Foundation

extension FileManager {
    
    func directoryExistAtPath(_ path: String) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        
        return exists && isDirectory.boolValue
    }
}

class FileManagerService {
    
    // MARK: - Singleton
    static let shared = FileManagerService()
    private init() {
        guard let searchDocumentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("Can't find path 'Error no. 1'")
        }
        
        let documentsPath = URL(fileURLWithPath: searchDocumentsPath)
        logsPath = documentsPath.appendingPathComponent("data")
    }
    
    var logsPath: URL
    
    func createDirectory(for name: String) {
        deleteDirectory(withName: name)
        createNeededDirectory(withName: name)
    }
    
    func createDirectoryForFile(url: String) {
        let lastSpace = url.lastIndex(of: "/") ?? url.endIndex
        let tempUrl = url[..<lastSpace]
        do {
            try FileManager.default.createDirectory(atPath: logsPath.path + tempUrl, withIntermediateDirectories: true, attributes: nil)
        } catch let err {
            print("\(err) 'Error no. 4'")
        }
    }
    
    func saveText(for fileName: String, value: String) {
        let file = "tmp.txt"
        let text = value
        let fileURL = logsPath
            .appendingPathComponent(fileName)
            .appendingPathComponent(file)
        
        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {
            print(error)
        }
    }
    
    func deleteDirectory(withName name: String) {
        FileManager.default
        do {
            guard FileManager.default.directoryExistAtPath(logsPath.path + "/" + name) else {
                print("\(logsPath.path + "/" + name) has exist")
                return
            }
            try FileManager.default.removeItem(atPath: logsPath.path + "/" + name)
        } catch let err {
            print("\(err) 'Error no. 3'")
        }
    }
    
    private func createNeededDirectory(withName name: String) {
        do {
            guard !FileManager.default.directoryExistAtPath(logsPath.path + "/" + name) else {
                print("\(logsPath.path + "/" + name) has exist")
                return
            }
            try FileManager.default.createDirectory(atPath: logsPath.path + "/" + name, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("\(error) 'Error no. 2'")
        }
    }
}

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
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
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
                FileManagerService.shared.createDirectory(for: "Files_from_Application")
                FileManagerService.shared.saveText(for: "Files_from_Application", value: self.textView.text)
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

