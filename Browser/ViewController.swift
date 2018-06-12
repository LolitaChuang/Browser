///////////////////////////////////////////////////////
//autolayout v.s. frame => UINavigationBar
//orientation
//view/view controller life cycle
//when need to call layoutIfNeeded manually; when it will be triggered automatically
//try, catch
//
//javascript handling..

///////////////////////////////////////////////////////
//  ViewController.swift
//  Browser
//
//  Created by lolitachuang on 2018/6/4.
//  Copyright © 2018年 lolitachuang. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    fileprivate var kNavItemContainerH: CGFloat = 30.0
    
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navItemContainer: UIView!
    
    
    @IBOutlet weak var backwardBtn: UIBarButtonItem!
    @IBOutlet weak var forwardBtn: UIBarButtonItem!
    @IBOutlet weak var reloadBtn: UIBarButtonItem!
    
    @IBOutlet weak var progressBar: UIProgressView!
    required init?(coder aDecoder: NSCoder) { // from storyboard
        //        let config = WKWebViewConfiguration(coder: ) // not sure if needed...
        //        webview = WKWebView(frame: .zero) // manually
        
        // customize the configuration file with the javascript file - injecting a javasript file to modify the webpage content
        // Q :
        // 1. 每一個需要以javascript處理的WKWebView都要設定custom configuration?
        // 2. 不能以storyboard產生這樣的WKWebView?因為需要設定custom configuration...; 可以設定多個script？=> Ans : Yes,
        // 3. 此WKWebView loads的所有網頁都會injecting此javascript...可以動態決定何時injection何時不做injection? => 應該是吧, 可以動態的addUserScript, removeAllUserScripts
        
        let configuration = WKWebViewConfiguration()
        
        if let scriptURL = Bundle.main.url(forResource: "hideSections", withExtension: "js") {
            //        if let filePath = Bundle.main.path(forResource: "hideSections", ofType: "js") { // 和使用URL的差別？
            let scriptContent = try! String(contentsOf: scriptURL, encoding: .utf8) // try的用法.....
            let script = WKUserScript(source: scriptContent, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
            
            configuration.userContentController.addUserScript(script)
            //            WKWebView(frame: <#T##CGRect#>, configuration: <#T##WKWebViewConfiguration#>
        }
        
        super.init(coder: aDecoder)
        //        webview.configuration = configuration -> compiler error : configuration是read-only要在init時assign; 可在subclass's init?(coder aDecoder: NSCoder)中, 但只有WKWebView(frame: <#T##CGRect#>, configuration: <#T##WKWebViewConfiguration#>)有configuration參數
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // .new : static var 是class variable? A: yes, 但無法被繼承
        webview.addObserver(self, forKeyPath: "loading", options: .new, context: nil) // not "isLoading"
        webview.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil) // 追蹤進度是用property
        webview.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        
        //        let url = URL(fileURLWithPath: "http://www.appcoda.com") // wrong api...
        let url = URL(string: "http://www.appcoda.com")
        if let url = url {
            webview.load(URLRequest(url: url))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        setupUI()
    }
    
    //    override var prefersStatusBarHidden: Bool {
    //        return false
    //    }
    
    // 因為navigation bar沒有autolayout, 所以在裝置轉向時, 手動重算
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator) // 不能少啊...
        
        /* 等著了解
         print("Before ==============================")
         print("screen width : \(UIScreen.main.bounds.size.width)")
         print("screen height : \(UIScreen.main.bounds.size.height)")
         
         coordinator.animate(alongsideTransition: { context in
         print("After ==============================")
         print("screen width : \(UIScreen.main.bounds.size.width)")
         print("screen height : \(UIScreen.main.bounds.size.height)")
         
         self.setNeedsStatusBarAppearanceUpdate()
         }) { context in
         print("width : \(size.width)")
         print("height : \(size.height)")
         
         self.navItemContainer.frame = CGRect(x:0, y: 0, width: size.width, height: self.kNavItemContainerH)
         self.navItemContainer.layoutIfNeeded()
         }
         */
        
        /* 時序有問題
         print("orientation : \(UIApplication.shared.statusBarOrientation)")
         if UIApplication.shared.statusBarOrientation == .landscapeLeft ||
         UIApplication.shared.statusBarOrientation == .landscapeRight {
         self.navItemContainer.frame = CGRect(x:0, y: UIApplication.shared.statusBarFrame.height, width: size.width, height: self.kNavItemContainerH)
         self.navItemContainer.layoutIfNeeded()
         } else {
         self.navItemContainer.frame = CGRect(x:0, y: 0, width: size.width, height: self.kNavItemContainerH)
         self.navItemContainer.layoutIfNeeded()
         }
         */
        
        print("orientation : \(UIApplication.shared.statusBarOrientation)")
        if UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight {
            self.navItemContainer.frame = CGRect(x:0, y: UIApplication.shared.statusBarFrame.height, width: size.width, height: self.kNavItemContainerH)
            self.navItemContainer.layoutIfNeeded()
        } else {
            self.navItemContainer.frame = CGRect(x:0, y: 0, width: size.width, height: self.kNavItemContainerH)
            self.navItemContainer.layoutIfNeeded()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupUI() {
        // UIBarButtonItems
        backwardBtn.isEnabled = false
        forwardBtn.isEnabled = false
        
        webview.navigationDelegate = self
        // manuall
        /*
         self.view.addSubview(webview)
         webview.navigationDelegate = self
         
         // autolayout
         webview.translatesAutoresizingMaskIntoConstraints = false
         let topConstraint = NSLayoutConstraint(item: webview, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0.0)
         let bottomConstraint = NSLayoutConstraint(item: webview, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0.0)
         let leftConstraint = NSLayoutConstraint(item: webview, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0.0)
         let rightConstraint = NSLayoutConstraint(item: webview, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0.0)
         
         let constraints = [topConstraint, bottomConstraint, leftConstraint, rightConstraint]
         self.view.addConstraints(constraints)
         */
        
        
        /* compiler errors :
         The view hierarchy is not prepared for the constraint: <NSLayoutConstraint:0x6080000970c0 V:|-(0)-[UITextField:0x7fbbd682fa00]   (inactive, names: '|':UIView:0x7fbbd5509750 )>
         When added to a view, the constraint's items must be descendants of that view (or the view itself). This will crash if the constraint needs to be resolved before the view hierarchy is assembled. Break on -[UIView(UIConstraintBasedLayout) _viewHierarchyUnpreparedForConstraint:] to debug.
         2018-06-05 11:42:30.166452+0800 Browser[50771:2236325] *** Assertion failure in -[UIView _layoutEngine_didAddLayoutConstraint:roundingAdjustment:mutuallyExclusiveConstraints:], /BuildRoot/Library/Caches/com.apple.xbs/Sources/UIKit_Sim/UIKit-3698.52.10/NSLayoutConstraint_UIKitAdditions.m:734
         2018-06-05 11:42:30.171101+0800 Browser[50771:2236325] *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Impossible to set up layout with view hierarchy unprepared for constraint.'
         */
        
        /* use autolayout
         searchBar.translatesAutoresizingMaskIntoConstraints = false
         let topConstraint = NSLayoutConstraint(item: searchBar, attribute: .top, relatedBy: .equal, toItem: navItemContainer, attribute: .top, multiplier: 1, constant: 10.0)
         let bottomConstraint = NSLayoutConstraint(item: searchBar, attribute: .bottom, relatedBy: .equal, toItem: navItemContainer, attribute: .bottom, multiplier: 1, constant: 0.0)
         let leftConstraint = NSLayoutConstraint(item: searchBar, attribute: .leading, relatedBy: .equal, toItem: navItemContainer, attribute: .leading, multiplier: 1, constant: 0.0)
         let rightConstraint = NSLayoutConstraint(item: searchBar, attribute: .trailing, relatedBy: .equal, toItem: navItemContainer, attribute: .trailing, multiplier: 1, constant: 0.0)
         
         let constraints = [topConstraint, bottomConstraint, leftConstraint, rightConstraint]
         //        searchBar.addConstraints(constraints) // wrong, compile fail
         self.navItemContainer.addConstraints(constraints)
         //        self.view.addConstraints(constraints) // wrong
         */
        
        // navItemContainer
        self.navItemContainer.backgroundColor = UIColor.cyan
        self.navItemContainer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: kNavItemContainerH)
        
        self.navItemContainer.layoutIfNeeded()
        //        self.navItemContainer.layoutSubviews()
    }
    
    private func setup() {
        
        
        //self.searchBar.setNeedsLayout() // 若在storyboard上設定然後在此trigger re-layout, searchBar仍無法抓到正確的constraints
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // The state of the back and forward buttons will be changed according to the current state of the web view.
        if keyPath == "loading" {
            backwardBtn.isEnabled = webview.canGoBack
            forwardBtn.isEnabled = webview.canGoForward
        } else if keyPath == "estimatedProgress" {
            progressBar.isHidden = (webview.estimatedProgress == 1.0)
            progressBar.setProgress(Float(webview.estimatedProgress), animated: true) // 要設定成動畫才能看到過程...
            //            progressBar.progress = Float(webview.estimatedProgress)
        } else if keyPath == "title" {
            self.title = webview.title
        }
    }
    
    @IBAction func backward(_ sender: UIBarButtonItem) {
        webview.goBack()
    }
    
    @IBAction func forward(_ sender: UIBarButtonItem) {
        webview.goForward()
    }
    
    @IBAction func reload(_ sender: UIBarButtonItem) {
        webview.reload()
    }
}

extension ViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Here we are!!")
        progressBar.setProgress(0.0, animated: false)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Here we are 1!!")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        
        //        if (navigationAction.navigationType == .linkActivated) && !(navigationAction.request.url?.host?.lowercased().hasPrefix("www.appcoda.com")) => compiler error
        //        if let lowercasedUrlStr = navigationAction.request.url?.host?.lowercased() {
        guard let hasPrefix = navigationAction.request.url?.host?.lowercased().hasPrefix("abc") else {
            <#statements#>
        }
        if navigationAction.navigationType == .linkActivated,
            let hasPrefix = navigationAction.request.url?.host?.lowercased().hasPrefix("abc") {
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
}

//struct Constants {
//
//}

extension ViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let str = textField.text
        var url:URL?
        
        if let urlStr = str {
            if urlStr.hasPrefix("http://") {
                url = URL(string: urlStr)
            } else {
                url = URL(string: ("http://" + urlStr))
            }
        } else {
            return false
        }
        
        if let url = url {
            webview.load(URLRequest(url: url))
        }
        
        textField.resignFirstResponder() // must add
        return true
    }
}




