//
//  Util.swift
//  FastlaneRunner
//
//  Created by kay on 2021/01/12.
//  Copyright © 2021 Joshua Liebowitz. All rights reserved.
//

import Foundation

/**
 앱 버전 정보
 - parameters:
    - current: 현재 버전정보
    - next: 변경된 버전 정보
    - isChanged: 버전 변경 여부
 */
struct AppVersion {
    
    static var current = Info(type: .current)
    static var next = Info(type: .next)
    
    static var isChanged: Bool {
        let equalVersion = Self.current.version == Self.next.version
        let equalBuildNumber = Self.current.buildNumber == Self.next.buildNumber
        return equalVersion == false || equalBuildNumber == false
    }
    
    static func fetch(type: `Type`, completion: Completion) {
        switch type {
        case .current:
            Self.current.update()
            completion(Self.current)
        case .next:
            Self.next.update()
            completion(Self.next)
        }
    }
    
    //MARK: - Defined
    
    enum `Type` {
        case current
        case next
    }
    
    struct Info {
        let type: AppVersion.`Type`
        var version: String = ""
        var buildNumber: String = ""
        var isEmpty: Bool {
            return version.isEmpty || buildNumber.isEmpty
        }
        var text: String {
            return isEmpty ? "" : "\(version)(\(buildNumber))"
        }
        var includeBuildNumberText: String {
            return isEmpty ? "" : "\(version)_\(buildNumber)"
        }

        
        mutating func update() {
            guard isEmpty == true else { return }
            self.version = getVersionNumber(xcodeproj: gymfile.project, target: gymfile.scheme)
            self.buildNumber = getBuildNumber(xcodeproj: gymfile.project)
        }
    }
    
    typealias Completion = (Info) -> Void

}

/// .env 에서 값을 읽어오기 위함
enum ENV: String {
    case project, scheme, output_directory
    case git_message_commit, git_message_tag
    case slack_url
    
    var value: String {
        return environmentVariable(get: self.rawValue)
    }
    
    var nsValue: NSString {
        return value as NSString
    }
}

/// 콘솔에 정형화된 메시지를 보여주기 위함.
struct Print {
    
    static var prefix: String = "###"
    
    static func message<T>(_ message: T?, with title: String? = nil) {
        guard let message = message else { return }
        Self.messages([message], with: title)
    }
    
    static func messages<T>(_ messages: [T]?, with title: String? = nil) {
        guard let messages = messages, messages.isEmpty == false else { return }
        puts(message: prefix)
        if let title = title {
            puts(message: "\(prefix) === \(title) === ")
        }
        messages.forEach({ puts(message: "\(prefix) \($0)") })
        puts(message: "")
    }
}

