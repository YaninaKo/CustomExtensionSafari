//
//  ActionViewController.swift
//  Extension
//
//  Created by Yanina Kovrakh on 10.01.2024.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    
    @IBOutlet var script: UITextView!
    
    let defaults = UserDefaults.standard
    
    var pageTitle = ""
    var pageURL = ""
    var savedScripts = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        let addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(selectScript))
        
        navigationItem.rightBarButtonItems = [doneBarButtonItem, addBarButtonItem]
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier as String) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    
                    if let savedData = self?.defaults.object(forKey: "savedScripts") as? Data {
                        let jsonDecoder = JSONDecoder()
                        
                        do {
                            self?.savedScripts = try jsonDecoder.decode([String: String].self, from: savedData)
                            DispatchQueue.main.async {
                                self?.script.text = self?.savedScripts[self?.pageURL ?? ""]
                            }
                        } catch {
                            print("Failed to decode UserDefaults: \(error)")
                        }
                    }
                                       
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
    }
    
    @objc func done() {
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text ?? ""]
        
        let webDistionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDistionary, typeIdentifier: UTType.propertyList.identifier as String)
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
        
        savedScripts[pageURL] = script.text
        save()
    }
    
    @objc func selectScript() {
        let ac = UIAlertController(title: "Select script", message: nil, preferredStyle: .alert)
        
        let scripts = ["alert('Hello world!')", "alert('Nice to see you!')"]
        
        for (_, script) in scripts.enumerated() {
            let action = UIAlertAction(title: script, style: .default) { [weak self] action in
                self?.script.text = script
                self?.done()
            }
            ac.addAction(action)
        }
        
        present(ac, animated: true)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedrange = script.selectedRange
        script.scrollRangeToVisible(selectedrange)
        
    }
    
    func save() {
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(savedScripts) {
            defaults.setValue(savedData, forKey: "savedScripts")
        } else {
            print("Failed to save showTimes data.")
        }
    }

}
