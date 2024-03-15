//
//  TimeCapsuleCell.swift
//  dxTimeCapsule
//
//  Created by 안유진 on 3/8/24.
//

import UIKit
import SnapKit
import FirebaseFirestoreInternal

class TimeCapsuleCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    // 셀 식별자
    static let identifier = "TimeCapsuleCell"
    
    // 캡슐 이미지를 표시하는 이미지 뷰
    lazy var registerImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 10
        image.layer.masksToBounds = true
        return image
    }()
    
    // D-Day 정보를 표시하는 레이블
    lazy var dDay: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemBlue
        label.font = UIFont.boldSystemFont(ofSize: 44)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()
    
    // 사용자 위치를 표시하는 레이블
    lazy var userLocation: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 60)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.2
        return label
    }()
    
    // 생성 날짜를 표시하는 레이블
    lazy var creationDate: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 38)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.35
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initialization
    
    // 초기화 메서드
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews() // 서브뷰들을 설정합니다.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews() // 서브뷰들을 설정합니다.
    }
    
    // MARK: - Configuration
    
    // 셀을 구성하는 메서드
    func configure(with capsuleInfo: TCInfo) {
        // 이미지 설정
        if let imageUrl = capsuleInfo.tcBoxImageURL, let url = URL(string: imageUrl) {
            self.registerImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        } else {
            self.registerImage.image = UIImage(named: "placeholder")
        }
        
        // D-Day 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // 한국 시간대 설정
        
        let today = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: today, to: capsuleInfo.openTimeCapsuleDate)
        
        if let daysUntilOpening = components.day {
            if daysUntilOpening == 0 {
                
                // (수정) 오늘이 개봉일일 때 "D-day" 반환
                self.dDay.text = "D-day"
            } else {
                let dDayPrefix = daysUntilOpening < 0 ? "D+" : "D-" // D-Day 표시
                self.dDay.text = "\(dDayPrefix)\(abs(daysUntilOpening))"
            }
        }
        // 사용자 위치 설정
        self.userLocation.text = capsuleInfo.userLocation ?? "Unknown location"
        
        // 생성 날짜 설정
        let dateStr = dateFormatter.string(from: capsuleInfo.createTimeCapsuleDate)
        self.creationDate.text = dateStr
    }
    
    // MARK: - Setup
    
    // 서브뷰들을 추가하고 Auto Layout을 설정하는 메서드
    private func setupViews() {
        contentView.addSubview(registerImage)
        contentView.addSubview(dDay)
        contentView.addSubview(userLocation)
        contentView.addSubview(creationDate)
        
        registerImage.snp.makeConstraints { make in
            let offset = UIScreen.main.bounds.height * (0.25/16.0)
            make.height.equalTo(registerImage.snp.width).multipliedBy(9.0/16.0)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        dDay.snp.makeConstraints { make in
            let offset1 = UIScreen.main.bounds.height * (0.15/16.0)
            let offset2 = UIScreen.main.bounds.height * (0.6/16.0)
            let offset3 = UIScreen.main.bounds.width * (0.05/2.0)
            make.top.equalTo(registerImage.snp.bottom).offset(offset1)
            make.leading.equalToSuperview().inset(offset3)
            make.width.equalTo(registerImage.snp.width).multipliedBy(0.2/1.0)
            make.height.equalTo(offset2)
        }
        
        userLocation.snp.makeConstraints { make in
            let offset1 = UIScreen.main.bounds.height * (0.3/16.0)
            let offset2 = UIScreen.main.bounds.width * (0.05/2.0)
            make.top.equalTo(registerImage.snp.bottom).offset(offset1)
            make.leading.equalTo(dDay.snp.trailing).offset(offset2)
            make.height.equalToSuperview().multipliedBy(2.1/16.0)
            make.trailing.equalToSuperview().inset(offset2)
        }
        
        creationDate.snp.makeConstraints { make in
            let offset = UIScreen.main.bounds.width * (0.05/2.0)
            let offset2 = UIScreen.main.bounds.height * (0.5/16.0)
            make.trailing.equalToSuperview().inset(offset)
            make.height.equalTo(offset2)
            make.top.equalTo(userLocation.snp.bottom)
        }
    }
}
//
//import SwiftUI
//struct PreVie10w: PreviewProvider {
//    static var previews: some View {
//        UpcomingTCViewController().toPreview()
//    }
//}
