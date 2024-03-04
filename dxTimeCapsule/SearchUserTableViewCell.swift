import UIKit
import SnapKit
import SDWebImage
import FirebaseAuth

class SearchUserTableViewCell: UITableViewCell {
    var user : User?
    var friendsViewModel: FriendsViewModel?
    var friendActionButtonTapAction: (() -> Void)?  // 친구 추가/요청 버튼 탭 시 실행될 클로저
    var userProfileImageView: UIImageView!
    var userNameLabel: UILabel!
    var friendActionButton: UIButton! // 친구 추가 또는 요청 수락 버튼
    var statusLabel: UILabel! // 상태를 나타내는 레이블


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - UI Setup
    
    private func setupUI() {
        
        userProfileImageView = UIImageView()
        userProfileImageView.layer.cornerRadius = 25
        userProfileImageView.clipsToBounds = true
        contentView.addSubview(userProfileImageView)
        
        //
        userNameLabel = UILabel()
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        contentView.addSubview(userNameLabel)
        
        // 친구 추가/요청 버튼 초기화
        friendActionButton = UIButton(type: .system)
        friendActionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        friendActionButton.layer.cornerRadius = 15
        friendActionButton.addTarget(self, action: #selector(friendActionButtonTapped), for: .touchUpInside)
        contentView.addSubview(friendActionButton)

        // 상태 레이블 초기화
        statusLabel = UILabel()
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        contentView.addSubview(statusLabel)
    }
    
    private func setupLayout() {
        userProfileImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(60)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(userProfileImageView.snp.trailing).offset(35)
        }
        
        friendActionButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-35)
            make.height.equalTo(30)
            make.width.equalTo(100)

        }
        
        statusLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-35)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }
    }
    
    // MARK: - Configuration
    func configure(with user: User, viewModel: FriendsViewModel) {
        self.user = user
        self.friendsViewModel = viewModel
        userNameLabel.text = user.username
        userProfileImageView.sd_setImage(with: URL(string: user.profileImageUrl ?? ""), placeholderImage: UIImage(named: "defaultProfileImage"))
        
        // 현재 로그인한 사용자 ID를 가져옴
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            // 로그인한 사용자 ID를 가져올 수 없는 경우, 버튼과 레이블을 숨김
            friendActionButton.isHidden = true
            statusLabel.isHidden = true
            return
        }

        // 사용자의 친구 상태에 따라 UI 업데이트
        updateFriendshipStatusUI(user: user, currentUserID: currentUserID)
    }

   // MARK: - Functions
    func updateFriendshipStatusUI(user: User, currentUserID: String) {
          // UI 업데이트 로직
          friendsViewModel?.checkFriendshipStatus(forUser: user.uid) { status in
              DispatchQueue.main.async {
                  switch status {
                      
                  case "이미 친구입니다":
                      self.friendActionButton.isHidden = true
                      self.statusLabel.text = "이미 친구인 상태"
                      self.statusLabel.textColor = .systemGray
                      self.statusLabel.font = UIFont.pretendardSemiBold(ofSize: 15)
                      self.statusLabel.isHidden = false
                      
                  case "요청 보냄":
                      self.friendActionButton.isHidden = true
                      self.statusLabel.text = "친구 요청 보냄"
                      self.statusLabel.textColor = .systemGray
                      self.statusLabel.font = UIFont.pretendardSemiBold(ofSize: 15)
                      self.statusLabel.isHidden = false
                      
                  case "요청 받음":
                      self.friendActionButton.isHidden = false
                      self.friendActionButton.setThemeBrokenHeart()
                      self.friendActionButton.setTitle("요청 받음", for: .normal)
                      self.friendActionButton.setTitleColor(.black, for: .normal)
                      self.friendActionButton.titleLabel?.font = UIFont.pretendardSemiBold(ofSize: 15)
                      self.statusLabel.isHidden = true
                      
                  default:
                      self.friendActionButton.isHidden = false
                      self.friendActionButton.setThemeBrokenHeart()
                      self.friendActionButton.setTitle("친구 신청", for: .normal)
                      self.friendActionButton.setTitleColor(.black, for: .normal)
                      self.friendActionButton.titleLabel?.font = UIFont.pretendardSemiBold(ofSize: 15)
                      self.statusLabel.isHidden = true
                  }
              }
          }
      }
      
        
    // MARK: - Actions
    @objc private func friendActionButtonTapped() {
        guard let user = user, let currentUserID = Auth.auth().currentUser?.uid else {
            print("사용자 정보 누락 또는 에러입니다.")
            return
        }
        friendsViewModel?.sendFriendRequest(toUser: user.uid, fromUser: currentUserID) { [weak self] success, error in
               DispatchQueue.main.async {
                   if success {
                       // 요청 성공 시, UI 즉시 업데이트
                       self?.updateFriendshipStatusUI(user: user, currentUserID: currentUserID)
                   } else {
                       // 에러 처리
                       print("친구 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                   }
               }
           }
       }
   }