// The Deliverfile allows you to store various App Store Connect metadata
// For more information, check out the docs
// https://docs.fastlane.tools/actions/deliver/

// In general, you can use the options available
// fastlane deliver --help

// Remove the // in front of the line to enable the option

public class Deliverfile: DeliverfileProtocol {
    // If you want to enable `deliver`, run `fastlane deliver init`
    // After, this file will be replaced with a custom implementation that contains values you supplied
    // during the `init` process, and you won't see this message
    
    public var force: Bool { return true }
    
    // 스크린샷 업로드 여부
    public var skipScreenshots: Bool { return true }
    
    // 메타데이터 업로드 여부
    public var skipMetadata: Bool { return false }
    
    // 바이너리 업로드 여부
    public var skipBinaryUpload: Bool { return false }
    
    // 리뷰 제출하기 여부
    public var submitForReview: Bool { return true }
    
    // 스토어에 자동 배포여부
    public var automaticRelease: Bool { return false }
    
    //
    // https://github.com/fastlane/fastlane/issues/5542#issuecomment-254201994
    public var submissionInformation: [String : Any]? {
        return ["add_id_info_limits_tracking": true,
                "add_id_info_serves_ads": false,
                "add_id_info_tracks_action": false,
                "add_id_info_tracks_install": true,
                "add_id_info_uses_idfa": true
        ]
    }
    
//    public var releaseNotes: String? {
//        return "Bug fixed"
//    }
    
    // 인앱결제
    public var precheckIncludeInAppPurchases: Bool { return false }
}
