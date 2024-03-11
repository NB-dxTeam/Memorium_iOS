//
//  OpenCapsuleViewController.swift
//  dxTimeCapsule
//
//  Created by 김우경 on 3/7/24.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import SDWebImage

class OpenCapsuleViewController: UIViewController {
    var documentId: String?

    private var topBarView: UIView!
    private var homeButton: UIButton!
    private var titleLabel: UILabel!
    private var separatorLine: UIView!
    private var logoImageView: UIImageView!
    private var locationLabel: UILabel!
    private var detailedAddressLabel: UILabel!
    private var capsuleImageView: UIImageView!
    private var memoryTextView: UITextView!
    private var messageButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUIComponents()
        setupHomeButton()  // 여기에 setupHomeButton 호출 추가
        loadTimeCapsuleData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        messageButton.setCustom1()
      }
    
    private func setupHomeButton() {
        homeButton = UIButton(type: .system)
        let homeImage = UIImage(systemName: "chevron.left") // SF Symbols에서 "house.fill" 이미지 사용
        homeButton.setImage(homeImage, for: .normal)
        homeButton.tintColor = UIColor(red: 209/255.0, green: 94/255.0, blue: 107/255.0, alpha: 1) // 버튼 색상 설정
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)

        topBarView.addSubview(homeButton) // topBarView에 버튼 추가
        homeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview() // 상단바 뷰의 센터와 맞춤
            make.width.height.equalTo(30) // 버튼의 크기 설정
        }
    }

    @objc private func homeButtonTapped() {
        // 모든 모달 뷰 컨트롤러를 닫고, 루트 뷰 컨트롤러로 돌아가기
        self.view.window?.rootViewController?.dismiss(animated: true, completion: {
            if let tabBarController = self.view.window?.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 0
            }
        })
    }

    private func setupUIComponents() {
        // 상단 바 뷰 설정
        topBarView = UIView()
//        topBarView.backgroundColor = .systemBlue // 상단 바의 배경색 설정
        view.addSubview(topBarView)
        topBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44) // 상단 바의 높이 설정
        }

        // 상단 바 타이틀 레이블 설정
         titleLabel = UILabel()
         titleLabel.numberOfLines = 0 // 여러 줄의 텍스트를 표시
         titleLabel.textAlignment = .center // 가운데 정렬
         
         // NSAttributedString 설정
         let userIdTextAttributes: [NSAttributedString.Key: Any] = [
             .font: UIFont.systemFont(ofSize: 12),
             .foregroundColor: UIColor.darkGray
         ]
         
         let timeCapsuleTextAttributes: [NSAttributedString.Key: Any] = [
             .font: UIFont.boldSystemFont(ofSize: 14),
             .foregroundColor: UIColor.black
         ]
         
         let userIdString = NSAttributedString(string: "사용자ID\n", attributes: userIdTextAttributes)
         let timeCapsuleString = NSAttributedString(string: "Time Capsule", attributes: timeCapsuleTextAttributes)
         
         let combinedAttributedString = NSMutableAttributedString()
         combinedAttributedString.append(userIdString)
         combinedAttributedString.append(timeCapsuleString)
         
         titleLabel.attributedText = combinedAttributedString
         
         topBarView.addSubview(titleLabel)
         titleLabel.snp.makeConstraints { make in
             make.centerX.equalToSuperview()
             make.centerY.equalToSuperview()
         }
        
        // 구분선 뷰 설정
            separatorLine = UIView()
            separatorLine.backgroundColor = UIColor.lightGray // 연한 그레이색 설정
            topBarView.addSubview(separatorLine)
            separatorLine.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(6) // 타이틀 레이블 아래에 위치
                make.leading.trailing.equalToSuperview() // 상단 바의 양쪽 가장자리에 맞춤
                make.height.equalTo(0.2) // 높이를 0.5로 설정하여 실선처럼 보이게 함
            }
        // 로고 이미지 뷰 설정
//        let logoImageView = UIImageView(image: UIImage(named: "pagelogo")) // 로고 이미지 설정
//        topBarView.addSubview(logoImageView) // 상단 바 뷰에 로고 이미지 뷰 추가
//        logoImageView.contentMode = .scaleAspectFit
//        logoImageView.snp.makeConstraints { make in
//            make.leading.equalTo(topBarView.snp.leading).offset(16)
//            make.centerY.equalTo(topBarView.snp.centerY)
//            make.height.equalTo(40) // 이미 설정된 높이
//            make.width.equalTo(150) // 너비 제약 조건 추가
//        }

        
        // 위치 레이블 초기화 및 설정
        locationLabel = UILabel()
        locationLabel.text = "더 현대 서울" // 초기값
        locationLabel.font = UIFont.systemFont(ofSize: 12) // 폰트 설정
        locationLabel.textAlignment = .center
        view.addSubview(locationLabel)
        locationLabel.textAlignment = .left
        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
        }

        // 세부 주소 레이블 초기화 및 설정
        detailedAddressLabel = UILabel()
        detailedAddressLabel.text = "서울 영등포구 여의대로 108" // 초기값
        detailedAddressLabel.font = UIFont.systemFont(ofSize: 10) // 폰트 설정
        detailedAddressLabel.textColor = .gray
        detailedAddressLabel.textAlignment = .center
        view.addSubview(detailedAddressLabel)
        detailedAddressLabel.textAlignment = .left
        detailedAddressLabel.snp.makeConstraints { make in
            make.leading.equalTo(locationLabel.snp.leading) // 위치 레이블과 동일한 leading
            make.top.equalTo(locationLabel.snp.bottom).offset(0.5)
        }

        // 이미지 뷰 설정
        capsuleImageView = UIImageView()
        capsuleImageView.contentMode = .scaleAspectFill // 이미지가 뷰를 꽉 채우도록 설정
        capsuleImageView.clipsToBounds = true // 이미지가 뷰 밖으로 나가지 않도록
        capsuleImageView.backgroundColor = .systemGray4 // 사용하지 않는 영역을 회색으로 표시

        view.addSubview(capsuleImageView)

        capsuleImageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview() // 슈퍼뷰의 양쪽 가장자리에 맞춥니다.
            make.top.equalTo(detailedAddressLabel.snp.bottom).offset(7)
            // 비율 제약 조건 (가로 대비 세로를 4:5로 설정) 인스타사이즈
            make.height.equalTo(capsuleImageView.snp.width).multipliedBy(5.0/4.0)
        }

        // 메모리 텍스트 뷰 설정
        memoryTextView = UITextView()
        memoryTextView.text =  """
                                지난 2022년 10월 6일은
                                지민님과 함께 보내셨군요!
                                굉장히 즐거웠던 날이에요.😋
                                """
        memoryTextView.isEditable = false
        memoryTextView.isScrollEnabled = false
        memoryTextView.font = UIFont.systemFont(ofSize: 14) // 폰트 설정
        memoryTextView.textAlignment = .center
        view.addSubview(memoryTextView)
        memoryTextView.snp.makeConstraints { make in
            make.top.equalTo(capsuleImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }

        // 메시지 확인하기 버튼 설정
        messageButton = UIButton(type: .system)
        messageButton.setTitle("그날의 메시지", for: .normal)
        messageButton.setCustom1() // 색상 설정
        messageButton.setTitleColor(.white, for: .normal)
        messageButton.layer.cornerRadius = 10
        view.addSubview(messageButton)
        messageButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-35)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(50)
        }

        // messageButton 이벤트 추가 (예시로 로그 출력)
        messageButton.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)
    }

    @objc private func messageButtonTapped() {
        print("메시지 확인하기 버튼이 탭되었습니다.")
    }
    
        private func loadTimeCapsuleData() {
            guard let documentId = documentId else { return }
            
            let db = Firestore.firestore()
            db.collection("timeCapsules").document(documentId).getDocument { [weak self] (document, error) in
                guard let self = self, let document = document, document.exists, let data = document.data() else {
                    print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // DateFormatter 설정
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy년 MM월 dd일 a hh시 mm분 ss초" // 원하는 날짜 형식 지정
                dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // 한국 시간대 설정
                dateFormatter.locale = Locale(identifier: "ko_KR") // 한국어로 표시
                
                // Date 처리
                if let creationDate = (data["creationDate"] as? Timestamp)?.dateValue(),
                   let openDate = (data["openDate"] as? Timestamp)?.dateValue() {
                    let creationDateString = dateFormatter.string(from: creationDate)
                    let openDateString = dateFormatter.string(from: openDate)
                    
                    // 추가 필드 처리 예시 (userLocation, photoUrl, mood 등)
                    // 예를 들어, 위치 정보와 기분 태그를 UI에 설정
                    DispatchQueue.main.async {
                        if let creationDate = data["creationDate"] as? Timestamp,
                           let friendID = data["friendID"] as? [String], // 친구의 ID가 배열로 있다고 가정
                           let mood = data["mood"] as? String {
                            let creationDateString = dateFormatter.string(from: creationDate.dateValue())
                            let friendNames = friendID.joined(separator: ", ") // 친구 이름을 콤마로 구분하여 하나의 문자열로 결합
                            
                            // 메모리 텍스트뷰에 표시할 문자열을 설정
                            self.memoryTextView.text = """
                                \(creationDateString)에
                                \(friendNames)과 함께 보내셨군요!
                                굉장히 행복했던 날이에요\(mood).
                                """
                        }
                    }
                    
                    // 이미지 URL 처리 및 표시
                    if let imageUrlString = data["photoUrl"] as? String, let imageUrl = URL(string: imageUrlString) {
                        self.capsuleImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
                        
              
                            }
                        }
                    }
                }
            }
     
    
        
    

