//
//  TranslationViewController.swift
//  Speech Recognition
//
//  Created by Joanna Frankiewicz on 17/08/2019.
//  Copyright © 2019 Joanna Frankiewicz. All rights reserved.
//

import UIKit
import Foundation

class TranslationViewController: UIViewController {
    
    var text:String!
    var image:UIImage!
    var sign:String!
    
    @IBOutlet weak var textTranslate: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftGoogleTranslate.shared.translate(text, sign, "en") { (text, error) in do {
            if let t = text
            {
                print(t)
                DispatchQueue.main.async(){
                    self.textTranslate.text = t
                    self.imageView.image = self.image
                }
            }
        }
    
        // Save data to file
        let fileName = "Output_file"
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
        print("FilePath: \(fileURL.path)")
        
        let writeString = text
        
        do {
            // Write to the file
            try writeString?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Failed to write to URL")
            print(error)
        }
        
        var readString = "" // Used to store the file contents
        do {
            // Read the file contents
            readString = try String(contentsOf: fileURL)
        } catch let error as NSError {
            print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
        }
        print("File Text: \(readString)")
    }
    
}
}

