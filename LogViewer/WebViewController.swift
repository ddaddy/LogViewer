//
//  WebViewController.swift
//  LogViewer
//
//  Created by Darren Jones on 14/06/2022.
//

import Foundation
import UIKit
import WebKit
import SwiftUI
import CryptoKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet var binButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    
    var documentURL: URL? {
        didSet {
            if oldValue != documentURL {
                lastParsedURL = nil
            }
            reloadWebView()
        }
    }
    
    var htmlString: String? {
        guard let documentURL = documentURL else { return nil }
        if documentURL.pathExtension == "elog" {
            if documentURL.startAccessingSecurityScopedResource(), let data = try? Data(contentsOf: documentURL) {
                documentURL.stopAccessingSecurityScopedResource()
                if let sealedBox = try? ChaChaPoly.SealedBox(combined: data) {
                    let key = SymmetricKey(data: SHA256.hash(data: "DJLogViewer".data(using: .utf8)!))
                    if let decryptedMessage = try? ChaChaPoly.open(sealedBox, using: key) {
                        return String(data: decryptedMessage, encoding: .utf8)
                    }
                }
            }
        } else {
            do {
                if documentURL.startAccessingSecurityScopedResource() {
                    let s = try String(contentsOf: documentURL)
                    documentURL.stopAccessingSecurityScopedResource()
                    return s
                }
                return try String(contentsOf: documentURL)
            } catch {
                print(error)
                return "\(error)"
            }
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyPendingOpenURLIfNeeded()
        reloadWebView()
    }
    
    private func displayButtons() {
        if let _ = documentURL {
            navigationItem.leftBarButtonItem = binButton
            navigationItem.rightBarButtonItem = refreshButton
        } else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        
        reloadWebView()
    }
    
    @IBAction func binButtonTapped(_ sender: Any) {
        
        documentURL = nil
    }
    
    private func reloadWebView() {
        
        Task {
            let string = htmlString ?? staticHTML
            
            let _ = webView.loadHTMLString(string, baseURL: nil)
            
            displayButtons()
            
            parse()
        }
    }
    
    private func applyPendingOpenURLIfNeeded() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let pendingURL = appDelegate.pendingOpenURL,
              pendingURL.isFileURL else { return }
        
        appDelegate.pendingOpenURL = nil
        documentURL = pendingURL
    }
    
    private func parse() {
        guard let _ = htmlString else { return }
        guard let documentURL = documentURL else { return }
        guard lastParsedURL != documentURL else { return }
        
        lastParsedURL = documentURL
        performSegue(withIdentifier: "segueToParsed", sender: self)
    }
    
    @IBSegueAction func segueToParsed(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: ParsedView(htmlString: htmlString))
    }
    
    private var staticHTML: String {
"""
<!DOCTYPE html>
<html>
<body>

<h1 style="text-align:center;">Use the iOS Share Sheet to open an html file</h1>

</body>
</html>
"""
    }
    
    private var lastParsedURL: URL?
}
