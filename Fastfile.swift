// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {

    var parameters: Parameters?
    
    //MARK: - Distribution Lanes
    
    func releaseLane(withOptions options: Options?) {
        desc("# Release Distribution Lane")
        desc("# bundle exec fastlane release version_update_type:patch upload_type:appstore")

        var parameters = Parameters(withOptions: options)
        parameters.version_update_type = parameters.version_update_type ?? .patch
        parameters.upload_type = parameters.upload_type ?? .appstore
        
        self.parameters = parameters

        distribution(withOptions: options)
    }
    
    func betaLane(withOptions options: Options?) {
        desc("# Beta Distribution Lane")
        desc("# bundle exec fastlane release version_update_type:build upload_type:testflight only_master_barnch:false")
        
        var parameters = Parameters(withOptions: options)
        parameters.version_update_type = parameters.version_update_type ?? .build
        parameters.upload_type = parameters.upload_type ?? .testflight
        parameters.only_master_barnch = false
        
        self.parameters = parameters
        
        distribution(withOptions: options)
    }
    
    func testLane(withOptions options: Options) {
        desc("# Test Distribution Lane")

    }
    
    //MARK: - Distribution

    func distribution(withOptions options: Options?) {
        
        readyLane(withOptions: options)
        versionUpdateLane(withOptions: options)
        buildLane(withOptions: options)
        uploadLane(withOptions: options)
        gitLane(withOptions: options)
        dsymUploadLane(withOptions: options)
    }

    //MARK: -
    //MARK: -- Ready

    func readyLane(withOptions options: Options?) {
        
        desc("# 준비 과정")
        
        let parameters = self.parameters ?? Parameters(withOptions: options)
        
        // LaneOpotions 표시
        UI.message("parameters: \(parameters)")
        
        if parameters.only_master_barnch {
            // 현재 브랜치 비교
            let currentBranch = gitBranch().components(separatedBy: "/").last ?? ""
            guard currentBranch == "master" else {
                fatalError("'master' 브랜치가 아닙니다. (현재 브런치: \(currentBranch))")
            }
        }
                
        if parameters.pod_update {
            // CocoaPods 업데이트
            cocoapods(repoUpdate: true, errorCallback: { (errorMessage) in
                fatalError(errorMessage)
            })
        }
    }

    //MARK: -
    //MARK: -- Version update

    /*! example
     bundle exec fastlane version version_update_type:patch
     bundle exec fastlane version version_update_type:minor
     bundle exec fastlane version version_update_type:major
     bundle exec fastlane version version_update_type:build
     **/

    func versionUpdateLane(withOptions options: Options?) {
        
        desc("# 버전 정보 업데이트 ")

        let parameters = self.parameters ?? Parameters(withOptions: options)

        defer {
            AppVersion.fetch(type: .next) { (info) in
                var messages = ["current version<build>: \(AppVersion.current.version)<\(AppVersion.current.buildNumber)>"]
                if AppVersion.isChanged {
                    messages.append("next version<build>: \(info.version)<\(info.buildNumber)>")
                    messages.append("is version changed ... true")
                }
                UI.messages(messages)
            }
        }

        guard let version_update_type = parameters.version_update_type else { return }
                        
        switch version_update_type {
        case .patch, .minor, .major:
            incrementVersionNumber(bumpType: version_update_type.rawValue)
            incrementBuildNumber(buildNumber: "1")
        case .build:
            incrementBuildNumber()
        default: break
        }
    }
        
    //MARK: -
    //MARK: -- App Build

    func buildLane(withOptions options: Options?) {
        
        desc("# 앱 빌드")
        
        let parameters = self.parameters ?? Parameters(withOptions: options)
        buildIosApp(scheme: gymfile.scheme,
                    outputDirectory: gymfile.outputDirectory,
                    configuration: parameters.build_configuration.rawValue,
                    exportXcargs: "-allowProvisioningUpdates")
    }
        
    //MARK: -
    //MARK: -- Upload to AppStoreConnect
    
    func uploadLane(withOptions options: Options?) {
        
        desc("# AppStoreConnect에 바이너리 업로드")
        
        let parameters = self.parameters ?? Parameters(withOptions: options)

        switch parameters.upload_type {
        case .appstore:
            uploadToAppStore(username: appleID,
                             skipBinaryUpload: deliverfile.skipBinaryUpload,
                             skipScreenshots: deliverfile.skipScreenshots,
                             skipMetadata: deliverfile.skipMetadata,
                             force: deliverfile.force,
                             submitForReview: deliverfile.submitForReview,
                             automaticRelease: deliverfile.automaticRelease,
                             precheckIncludeInAppPurchases: deliverfile.precheckIncludeInAppPurchases,
                             app: appIdentifier)
        case .testflight:
            uploadToTestflight(username: appleID)
        case .uploadOnly:
            uploadToTestflight(username: appleID, skipSubmission: true)
        default:
            break
        }
    }
        
    //MARK: -
    //MARK: -- Git Commit / Tag / Push

    func gitLane(withOptions options: Options?) {
        
        desc("# Git, add, commit, tag, push")
        
        let parameters = self.parameters ?? Parameters(withOptions: options)
        

        AppVersion.fetch(type: .next) { (info) in
            // 버전정보가 변경사항이 있을때만 git
            
            var messages = [String]()
            messages.append("current version<build>: \(AppVersion.current.version)<\(AppVersion.current.buildNumber)>")
            messages.append("next version<build>: \(AppVersion.next.version)<\(AppVersion.next.buildNumber)>")
            messages.append("is version changed: \(AppVersion.isChanged)")
            UI.messages(messages)

            if AppVersion.isChanged {
                
                let commitMessageFormat: NSString = ENV.git_message_commit.nsValue
                let commitMessage = NSString(format: commitMessageFormat, AppVersion.next.includeBuildNumberText) as String
            
                let tagMessageFormat: NSString = ENV.git_message_tag.nsValue
                let tagMessage = NSString(format: tagMessageFormat, AppVersion.next.text) as String
        
                UI.message("commitMessage: \(commitMessage)")
                UI.message("tagMessage: \(tagMessage)")

                gitAdd(path: "*")
                gitCommit(path: "*", message: commitMessage)
                if parameters.upload_type == .appstore {
                    addGitTag(tag: tagMessage)
                }
                pushToGitRemote()
            
            }
        }
    }
    
    //MARK: -
    //MARK: -- DSYM

    func dsymUploadLane(withOptions options: Options?) {
        
        let parameters = self.parameters ?? Parameters(withOptions: options)

        /// step1. AppStoreConnect에서 DSYM 파일들을 다운로드
        downloadDsyms(username: appleID,
                      appIdentifier: appIdentifier,
                      version:parameters.dsym_upload_type.stringValue,
                      minVersion: parameters.version)
        
        guard let dsymPaths = laneContext()["DSYM_PATHS"] as? [String] else {
            UI.message("dsymPaths nothing ...")
            return
        }
        
        UI.message("DSYM_PATHS: \(dsymPaths)")

        /// step2. 다운로드 받은 DSYM 파일들을 Firebase에 업로드
        dsymPaths.forEach({ uploadSymbolsToCrashlytics(dsymPath: $0, gspPath: ENV.google_service_info_path.value) })
        
        /// step3. 다운로드 받은 DSYM 파일들 제거
        cleanBuildArtifacts()
    }
    
    //MARK: -
    //MARK: -- Slack
    
    func slackLane(withOptions options: Options?) {
        if let message = options?["message"] {
            to_slack(message: message)
        }
        else {
            let parameters = self.parameters ?? Parameters(withOptions: options)
            if let message = parameters.upload_type?.successMessage {
                to_slack(message: message)
            }
        }
    }
    
    func to_slack(message: String?, success: Bool = true, errorInfo: String? = nil) {
        
        let slackUrl = ENV.slack_url.value
        guard slackUrl.isEmpty == false else { return }
        
        let payload: [String : String] = {
            let now = DateFormatter().string(from: Date())
            
            return ["Build Date": "\(now)",
                    "Built by": "campios",
                    "App Version": AppVersion.next.text]
        }()
        
        let attachments: [String: Any] = {
            var returnValue = [String: Any]()
            if let errorInfo = errorInfo {
                let fields: [String: Any] = ["title": "Error",
                                             "value": errorInfo,
                                             "short": false]
                returnValue["fields"] = [fields]
            }
            return returnValue
        }()

        slack(message: message, slackUrl: slackUrl, payload: payload, attachmentProperties: attachments, success: success)
    }

    //MARK: - Lifecycle

    func beforeAll(with lane: String) {
        
        // fastlane 최신버전 아니면 업데이트
        updateFastlane()
        
        // 현재버전 가져오기
        AppVersion.current.update()
    }
    
    func afterAll(with lane: String) {
        if let message = self.parameters?.upload_type?.successMessage {
            to_slack(message: message)
        }
    }
    
    func onError(currentLane: String, errorInfo: String) {
        UI.message("ERROR: \(currentLane), errorInfo: \(errorInfo)")
        let message = self.parameters?.upload_type?.failureMessage ?? "\(currentLane) 실패 .."
        to_slack(message: message, success: false, errorInfo: errorInfo)
    }
}
