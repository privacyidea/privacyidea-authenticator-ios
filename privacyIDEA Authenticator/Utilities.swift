//
// Created by Nils Behlen on 31.08.18.
// Copyright (c) 2018 Nils Behlen. All rights reserved.
//

import Foundation
import os

typealias U = Utilities

class Utilities {
    
    //MARK: CONVERSIONS
    func b64Tob64URLSafe(_ string: String) -> String {
        if string.contains("+") || string.contains("/") {
            return string.replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
        }
        return string
    }
    
    func b64URLSafeTob64(_ string: String) -> String {
        if string.contains("-") || string.contains("_") {
            return string.replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
        }
        return string
    }
    
    public static func log(_ message: Any, function: String = #function, file: String = #file, line: Int = #line) {
        #if DEBUG
        let fileStr: String = String(file.split(separator: "/").last ?? "")
        os_log("%{public}s", "[\(fileStr):\(line)][\(function)] \(message)")
        #endif
    }
}

