//
//  SingleWebViewViewController.swift
//  WebView In ScroolView
//
//  Created by Will on 05/08/2020.
//  Copyright © 2020 gewill.org. All rights reserved.
//

import SwifterSwift
import UIKit
import WebKit

class SingleWebViewViewController: UIViewController {
    // MARK: - outlets

    var webView: WKWebView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        var path = "https://m.fengniao.com"
        path = "https://weitoutiao.zjurl.cn/ugc/share/thread/1672918886208520/?app=&target_app=13"
        path = "https://haval-restructure-h5-test.beantechyun.cn/#/postDetails?postId=2810469196581953536&terminal=GW_APP_Haval"

        if let url = URL(string: path) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringCacheData
            webView.load(request)
        }
    }

    private func setupUI() {
        navigationController?.makeTransparent(withTint: UIColor.systemGreen)

        view.addSubview(webView)
        webView.frame = view.bounds
    }
}
