//
//  IPaFlickrWebViewController.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/9.
//

import UIKit
import WebKit
class IPaFlickrWebViewController: UIViewController {
    var request:URLRequest!
    var complete:((Result<IPaFlickr.UserInfo,Error>)->())!
    lazy var webView:WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        webView.navigationDelegate = self
        return webView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.onClose(_:)))]
        self.webView.load(request)
        // Do any additional setup after loading the view.
    }
    
    @objc func onClose(_ sender:Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension IPaFlickrWebViewController:WKNavigationDelegate
{
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,url.absoluteString.hasPrefix(IPaFlickr.oauthCallback) {
            decisionHandler(.cancel)
            IPaFlickr.shared.completeAuth(url) { (result) in
                
                self.complete(result)
                DispatchQueue.main.async {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
                
            }
        }
        else {
            decisionHandler(.allow)
        }
    }
}
