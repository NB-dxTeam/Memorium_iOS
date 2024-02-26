import Foundation
import FirebaseFirestore
import FirebaseAuth

struct User {
    var uid: String
    var email: String
    var nickname: String
    var friends: [String]? // 친구 리스트
    var profileImageUrl: String? // 프로필 이미지 URL
    var friendRequestsSent: [String]? // 친구 요청이 전송된 사용자 ID 배열
    var friendRequestsReceived: [String]? // 친구 요청을 받은 사용자 ID 배열
}
