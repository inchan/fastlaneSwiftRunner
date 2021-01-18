//
//  LaneOptions.swift
//  FastlaneSwiftRunner
//
//  Created by kay on 2021/01/12.
//  Copyright © 2021 Joshua Liebowitz. All rights reserved.
//

import Foundation

typealias Options = [String: String]

struct Parameters: Codable {
        
    /// 버저닝 타입.
    var version_update_type: Version_update_type?
    
    /// 빌드 구성 (Releaes, Debug)
    var build_configuration: Build_Configuration = .Release
    
    /// 업로드 타입
    var upload_type: Upload_Type?
    
    /// DSYM 업로드 타입
    var dsym_upload_type: DSYM_Upload_Type = .latest
    
    /// 선택된 버전
    var version: String? = nil
    
    /// 선택된 빌드 넘버
    var build_number: String? = nil
    
    /// pod 업데이트 여부
    var pod_update: Bool = true
    
    /// 마스터 브랜치 비교 여부 
    var only_master_barnch: Bool = true
    
        
    init(withOptions options: Options?) {
        if let version_update_type = Version_update_type(withOptions: options) {
            self.version_update_type = version_update_type
        }

        if let build_configuration = Build_Configuration(withOptions: options) {
            self.build_configuration = build_configuration
        }

        if let upload_type = Upload_Type(withOptions: options) {
            self.upload_type = upload_type
        }

        self.version = options?["version"]
        self.build_number = options?["build_number"]
        
        if let is_update_cocoapods = options?["pod_update"] {
            self.pod_update = (is_update_cocoapods == "true")
        }
        
        if let is_only_master_barnch = options?["only_master_barnch"] {
            self.only_master_barnch = (is_only_master_barnch == "true")
        }
    }
}

//MARK: - Option Protocol

protocol OptionTypeProtocol: RawRepresentable, CaseIterable, Codable where RawValue == String {
    // identifier
    static var key: String { get }
    // init
    init?(withOptions options: Options?)
}

extension OptionTypeProtocol {
    
    static var key: String { return String(describing: self).lowercased() }
    
    init?(withOptions options: Options?) {
        let value = options?[Self.key]
        if let element = Self.allCases
            .compactMap({ $0 })
            .filter({ "\($0)".lowercased() == value?.lowercased() })
            .first {
            self = element
        }
        else {
            return nil
        }
    }
}


enum Version_update_type: String, OptionTypeProtocol {
    
    case patch, minor, major, build, none
}

enum Build_Configuration: String, OptionTypeProtocol {
    
    case Release, Debug
}

enum Upload_Type: String, OptionTypeProtocol {
    
    case appstore, testflight, uploadOnly, none

    private var name: String {
        switch self {
        case .appstore: return "앱스토어"
        case .testflight: return "테스트 플라이트"
        case .uploadOnly: return "빌드"
        default: return ""
        }
    }
    
    var successMessage: String { return name.isEmpty ? "" : "\(name) 제출 성공!!" }
    
    var failureMessage: String { return name.isEmpty ? "" : "\(name) 제출 실패..." }
}

enum DSYM_Upload_Type: String, OptionTypeProtocol {
    
    case latest // app store connect에 올라간 마지막 버전
    case live   // App Store에 게시된 버전
    case all    // 전체
    case none
    
    var stringValue: String? {
        switch self {
        case .latest, .live: return self.rawValue
        default: return nil
        }
    }
}
