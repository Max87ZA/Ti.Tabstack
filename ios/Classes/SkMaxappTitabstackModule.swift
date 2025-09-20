//
//  SkMaxappTitabstackModule.swift
//  TiTabstack
//
//  Created by Marian Kucharcik
//  Copyright (c) 2025 Your Company. All rights reserved.
//

import UIKit
import TitaniumKit

/**
 
 Titanium Swift Module Requirements
 ---
 
 1. Use the @objc annotation to expose your class to Objective-C (used by the Titanium core)
 2. Use the @objc annotation to expose your method to Objective-C as well.
 3. Method arguments always have the "[Any]" type, specifying a various number of arguments.
 Unwrap them like you would do in Swift, e.g. "guard let arguments = arguments, let message = arguments.first"
 4. You can use any public Titanium API like before, e.g. TiUtils. Remember the type safety of Swift, like Int vs Int32
 and NSString vs. String.
 
 */

@objc(SkMaxappTitabstackModule)
class SkMaxappTitabstackModule: TiModule {

  
    
    // MARK: - Exports

    @objc(infoForTab:)
    func infoForTab(args: [Any]?) -> [String: Any] {
        guard let tabProxy = args?.first as? TiProxy else {
            return ["count": 0, "isRootVisible": true, "topTitle": NSNull(), "debugPath": "No tab proxy"]
        }
        let nav = navController(forTabProxy: tabProxy)
        return digest(nav: nav)
    }

    @objc(stackCount:)
    func stackCount(args: [Any]?) -> NSNumber {
        guard let tabProxy = args?.first as? TiProxy else { return 0 }
        let nav = navController(forTabProxy: tabProxy)
        return NSNumber(value: nav?.viewControllers.count ?? 0)
    }

    @objc(isRootVisible:)
    func isRootVisible(args: [Any]?) -> NSNumber {
        guard let tabProxy = args?.first as? TiProxy else { return 1 } // true by default
        let nav = navController(forTabProxy: tabProxy)
        let c = nav?.viewControllers.count ?? 0
        return NSNumber(value: c <= 1)
    }

    @objc(topTitle:)
    func topTitle(args: [Any]?) -> Any {
        guard let tabProxy = args?.first as? TiProxy else { return NSNull() }
        let nav = navController(forTabProxy: tabProxy)
        let title = nav?.topViewController?.navigationItem.title
        return title ?? NSNull()
    }

    // Convenience: pass a TabGroup to inspect its selected tab
    @objc(infoForSelectedTab:)
    func infoForSelectedTab(args: [Any]?) -> [String: Any] {
        guard let tgProxy = args?.first as? TiProxy else {
            return ["count": 0, "isRootVisible": true, "topTitle": NSNull(), "debugPath": "No tabgroup proxy"]
        }
        let selectedNav = selectedNavController(inTabGroupProxy: tgProxy)
        return digest(nav: selectedNav)
    }

    // MARK: - Helpers

    private func digest(nav: UINavigationController?) -> [String: Any] {
        guard let nav else {
            return ["count": 0, "isRootVisible": true, "topTitle": NSNull(), "debugPath": "No UINavigationController"]
        }
        let count = nav.viewControllers.count
        let isRoot = (count <= 1)
        let top = nav.topViewController?.navigationItem.title ?? nav.topViewController?.title
        let path = "UITabBarController > UINavigationController(count=\(count)) > UIViewController(\(top ?? "nil"))"
        return [
            "count": count,
            "isRootVisible": isRoot,
            "topTitle": top ?? NSNull(),
            "debugPath": path
        ]
    }

    /// Attempts to fetch the UINavigationController backing a Ti.UI.Tab proxy.
    /// Titanium does not expose this publicly, so we use defensive KVC to reach the native controller chain.
    private func navController(forTabProxy tabProxy: TiProxy) -> UINavigationController? {
        // Typical chain: TiUITabProxy -> (private) controller (UITabBarController's child) -> UINavigationController
        if let nav = tryKVC(tabProxy, keys: ["navigationController", "navController"]) as? UINavigationController {
            return nav
        }
        if let vc = tryKVC(tabProxy, keys: ["controller", "viewController"]) as? UIViewController {
            // If this VC is already a UINavigationController, return it
            if let nav = vc as? UINavigationController { return nav }
            // If VC is embedded in a nav
            if let nav = vc.navigationController { return nav }
            // Sometimes tab proxies expose their tab's controller via 'tab' key
            if let tabVC = tryKVC(tabProxy, keys: ["tab"]) as? UIViewController {
                if let nav = tabVC as? UINavigationController { return nav }
                if let nav = tabVC.navigationController { return nav }
            }
        }
        // Last resort: walk up from selected tab of the tab group if possible
        if let tg = tryKVC(tabProxy, keys: ["tabGroup", "tabgroup", "group"]) as? TiProxy {
            return selectedNavController(inTabGroupProxy: tg)
        }
        return nil
    }

    private func selectedNavController(inTabGroupProxy tgProxy: TiProxy) -> UINavigationController? {
        // KVC lookups against common internal keys
        if let tbc = tryKVC(tgProxy, keys: ["controller", "viewController"]) as? UITabBarController {
            if let selected = tbc.selectedViewController as? UINavigationController { return selected }
            if let selected = tbc.selectedViewController, let nav = selected.navigationController { return nav }
        }
        if let selectedVC = tryKVC(tgProxy, keys: ["selectedViewController", "selected"]) as? UIViewController {
            if let nav = selectedVC as? UINavigationController { return nav }
            if let nav = selectedVC.navigationController { return nav }
        }
        return nil
    }

    private func tryKVC(_ obj: NSObject, keys: [String]) -> AnyObject? {
        for key in keys {
            do {
                let val = obj.value(forKey: key) as AnyObject?
                if val != nil { return val }
            } catch { continue }
        }
        return nil
    }
}
