//
//  ViewController.swift
//  WebView In ScroolView
//
//  Created by Will on 22/07/2020.
//  Copyright © 2020 gewill.org. All rights reserved.
//

import SwifterSwift
import UIKit
import WebKit

class WebViewViewController: UIViewController {
    // MARK: - outlets

    var webView: WKWebView = WKWebView()
    var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    var containerScrollView: UIScrollView = UIScrollView()
    var contentView: UIView = UIView()
    var topView: UIView = UIView()

    // MARK: - properties

    private var lastWebViewContentHeight: CGFloat = 0.0
    private var lastTableViewContentHeight: CGFloat = 0.0

    private var webViewToken: NSKeyValueObservation?
    private var tableViewToken: NSKeyValueObservation?

    private var isPinToTableView = true

    // MARK: - life cycle

    deinit {
        webViewToken?.invalidate()
        tableViewToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        addObservers()

        var path = "https://m.fengniao.com"
//        path = "https://weitoutiao.zjurl.cn/ugc/share/thread/1672918886208520/?app=&target_app=13"

        if let url = URL(string: path) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringCacheData
            webView.load(request)
        }
    }

    private func setupUI() { navigationController?.makeTransparent(withTint: UIColor.systemGreen)

        contentView.addSubview(topView)
        contentView.addSubview(webView)
        contentView.addSubview(tableView)

        view.addSubview(containerScrollView)
        containerScrollView.addSubview(contentView)

        containerScrollView.frame = view.bounds
        contentView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height * 2)
        topView.frame = CGRect(x: 0, y: 0, width: view.width, height: 200)
        webView.frame = CGRect(x: 0, y: 0, width: view.width, height: 0.1)
        tableView.frame = view.bounds

        webView.top = topView.height
        webView.height = view.height
        tableView.top = webView.bottom

        topView.backgroundColor = UIColor.systemGreen

        containerScrollView.delegate = self
        containerScrollView.alwaysBounceVertical = true

        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self

        tableView.register(cellWithClass: UITableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
    }

    private func addObservers() {
        webViewToken = webView.observe(\.scrollView.contentSize, options: .new) { [weak self] _, _ in
            guard let `self` = self else { return }
            self.updateContainerScrollViewContentSize()
        }

        tableViewToken = tableView.observe(\.contentSize, options: .new) { [weak self] _, _ in
            guard let `self` = self else { return }
            self.updateContainerScrollViewContentSize()
        }
    }

    private func updateContainerScrollViewContentSize() {
        let webViewContentHeight = webView.scrollView.contentSize.height
        let tableViewContentHeight = tableView.contentSize.height

        if webViewContentHeight == lastWebViewContentHeight && tableViewContentHeight == lastTableViewContentHeight {
            return
        }

        lastWebViewContentHeight = webViewContentHeight
        lastTableViewContentHeight = tableViewContentHeight

        containerScrollView.contentSize = CGSize(width: view.width, height: webView.top + webViewContentHeight + tableViewContentHeight)

        let webViewHeight = (webViewContentHeight < view.height) ? webViewContentHeight : view.height
        let tableViewHeight = tableViewContentHeight < view.height ? tableViewContentHeight : view.height
        webView.height = webViewHeight <= 0.1 ? 0.1 : webViewHeight
        contentView.height = webView.top + webViewHeight + tableViewHeight
        tableView.height = tableViewHeight
        tableView.top = webView.bottom

        scrollViewDidScroll(containerScrollView)
    }
}

extension WebViewViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if containerScrollView != scrollView {
            return
        }

        var offsetY = scrollView.contentOffset.y

        let webViewHeight = webView.height
        let tableViewHeight = tableView.height

        let webViewContentHeight = webView.scrollView.contentSize.height
        let tableViewContentHeight = tableView.contentSize.height

        let webViewTop = webView.top

        let netOffsetY = offsetY - webViewTop

        switch containerScrollView.panGestureRecognizer.state {
        case .began, .changed, .ended:
            if isPinToTableView {
                isPinToTableView = false
                scrollView.contentOffset.y = webViewTop + webViewContentHeight
            }
        default: break
        }

        if isPinToTableView {
            let webViewHeight = (webViewContentHeight < view.height) ? webViewContentHeight : view.height
            webView.height = webViewHeight <= 0.1 ? 0.1 : webViewHeight

            offsetY = webViewHeight + webViewTop
            scrollView.contentOffset.y = offsetY
            contentView.top = offsetY - webViewHeight - webViewTop
            tableView.contentOffset = CGPoint(x: 0, y: 0)
            webView.scrollView.contentOffset = CGPoint(x: 0, y: webViewContentHeight - webViewHeight)
            return
        }

        print("✌️netOffsetY:\(netOffsetY), offsetY:\(offsetY), webViewTop:\(webViewTop), webViewContentHeight:\(webViewContentHeight), tableViewContentHeight:\(tableViewContentHeight)")

        if netOffsetY <= 0 {
            print("1区间段：WebView上方")
            contentView.top = 0
            webView.scrollView.contentOffset = CGPoint.zero
            tableView.contentOffset = CGPoint.zero
        } else if netOffsetY < webViewContentHeight - webViewHeight {
            print("2区间段：WebView可滚动范围")
            contentView.top = netOffsetY
            webView.scrollView.contentOffset = CGPoint(x: 0, y: netOffsetY)
            tableView.contentOffset = CGPoint.zero
        } else if netOffsetY < webViewContentHeight {
            print("3区间段：WebView高度范围")
            contentView.top = webViewContentHeight - webViewHeight
            webView.scrollView.contentOffset = CGPoint(x: 0, y: webViewContentHeight - webViewHeight)
            tableView.contentOffset = CGPoint.zero
        } else if netOffsetY < webViewContentHeight + tableViewContentHeight - tableViewHeight {
            print("4区间段：TableView可滚动范围")
            contentView.top = offsetY - webViewHeight - webViewTop
            tableView.contentOffset = CGPoint(x: 0, y: offsetY - webViewContentHeight - webViewTop)
            webView.scrollView.contentOffset = CGPoint(x: 0, y: webViewContentHeight - webViewHeight)
        } else if netOffsetY <= webViewContentHeight + tableViewContentHeight {
            print("5区间段：TableView高度范围，以及下方")
            contentView.top = containerScrollView.contentSize.height - contentView.height
            webView.scrollView.contentOffset = CGPoint(x: 0, y: webViewContentHeight - webViewHeight)
            tableView.contentOffset = CGPoint(x: 0, y: tableViewContentHeight - tableViewHeight)
        }
    }
}

extension WebViewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self)
        cell.textLabel?.text = indexPath.row.description
        cell.selectionStyle = .none

        return cell
    }
}

extension WebViewViewController: UITableViewDelegate {
}

extension WebViewViewController: WKNavigationDelegate {
}
