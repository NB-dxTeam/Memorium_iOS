//
//  TimeCapsuleCell.swift
//  dxTimeCapsule
//
//  Created by 안유진 on 3/8/24.
//

import UIKit
import SnapKit
import FirebaseFirestoreInternal

class TimeCapsuleCell: UITableViewCell {
    
    // MARK: - Properties
    static let identifier = "TimeCapsuleCell"
    
    enum DDayLogicType {
        case UpcomingTCViewControllerLogic
        case OpenedTCViewControllerLogic
    }
    
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
    lazy var dDayBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 12 // 모서리 둥글기 반지름 설정
        view.clipsToBounds = true // 모서리 둥글기 적용을 위해 필요
        return view
    }()
    
    // D-Day 정보를 표시하는 레이블
    lazy var dDayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 44, weight: .bold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.25
        label.textColor = .white
        label.textAlignment = .center
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
        label.font = UIFont.systemFont(ofSize: 44)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.3
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initialization
    
    // 초기화 메서드
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews() // 서브뷰들을 설정합니다.
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews() // 서브뷰들을 설정합니다.
    }
    
    // MARK: - Configuration
    
    // 셀을 구성하는 메서드
    func configure(with timeBox: TimeBox, dDayColor: UIColor, controllerType: DDayLogicType) {
        // 이미지 설정
        if let imageUrl = timeBox.thumbnailURL ?? timeBox.imageURL?.first, let url = URL(string: imageUrl) {
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
        
        if controllerType == .UpcomingTCViewControllerLogic {
            // UpcomingTCViewController의 D-Day 로직
            if let openTimeBoxDate = timeBox.openTimeBoxDate?.dateValue() {
                let components = calendar.dateComponents([.day], from: today, to: openTimeBoxDate)
                
                if let daysUntilOpening = components.day {
                    if daysUntilOpening == 0 {
                        self.dDayLabel.text = "D-day"
                    } else {
                        let dDayPrefix = daysUntilOpening < 0 ? "D+" : "D-"
                        self.dDayLabel.text = "\(dDayPrefix)\(abs(daysUntilOpening))"
                    }
                    self.dDayBackgroundView.backgroundColor = dDayColor
                }
            }
        } else if controllerType == .OpenedTCViewControllerLogic {
            // OpenedTCViewController의 D-Day 로직
            if let createTimeBoxDate = timeBox.createTimeBoxDate?.dateValue() {
                let components = calendar.dateComponents([.day], from: createTimeBoxDate, to: today)
                if let daysSinceCreation = components.day {
                    let dDayPrefix = daysSinceCreation < 0 ? "D+" : "D-"
                    self.dDayLabel.text = "\(dDayPrefix)\(abs(daysSinceCreation))"
                    self.dDayBackgroundView.backgroundColor = dDayColor
                }
            }
        }
        
        // 사용자 위치 설정
        self.userLocation.text = timeBox.addressTitle ?? "Unknown location"
        
        // 생성 날짜 설정
        if let createTimeBoxDate = timeBox.createTimeBoxDate?.dateValue() {
            let dateStr = dateFormatter.string(from: createTimeBoxDate)
            self.creationDate.text = dateStr
        }
    }

    
    // MARK: - Setup
    
    // 서브뷰들을 추가하고 Auto Layout을 설정하는 메서드
    private func setupViews() {
//        contentView.backgroundColor = .yellow
        contentView.addSubview(registerImage)
        contentView.addSubview(dDayBackgroundView)
        contentView.addSubview(userLocation)
        contentView.addSubview(creationDate)
    
        
        registerImage.snp.makeConstraints { make in
            let offset = UIScreen.main.bounds.height * (0.3/16.0)
            make.top.equalToSuperview().inset(offset)
            make.height.equalTo(registerImage.snp.width).multipliedBy(9.0/16.0)
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
        
        dDayBackgroundView.snp.makeConstraints { make in
            let offset1 = UIScreen.main.bounds.height * (0.3/16.0)
            let offset2 = UIScreen.main.bounds.height * (0.3/16.0)
            make.top.equalTo(registerImage.snp.bottom).offset(offset1)
            make.bottom.equalTo(userLocation.snp.bottom)
            make.leading.equalToSuperview().inset(30)
            make.width.equalTo(registerImage.snp.width).multipliedBy(0.17/1.0)
            make.height.equalToSuperview().multipliedBy(1.3/16.0)
        }
        dDayBackgroundView.addSubview(dDayLabel)
        
        // dDayLabel의 레이아웃을 dDayBackgroundView 내부 중앙에 맞춤
        dDayLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)) // 여백 조정
        }
        
        userLocation.snp.makeConstraints { make in
            let offset1 = UIScreen.main.bounds.height * (0.3/16.0)
            let offset2 = UIScreen.main.bounds.width * (0.10/2.0)
            make.top.equalTo(registerImage.snp.bottom).offset(offset1)
            make.leading.equalTo(dDayBackgroundView.snp.trailing).offset(offset2)
            make.height.equalToSuperview().multipliedBy(1.3/16.0)
            make.trailing.equalTo(creationDate.snp.leading)
        }
        
        creationDate.snp.makeConstraints { make in
            let offset = UIScreen.main.bounds.height * (0.35/16.0)
            make.trailing.equalToSuperview().inset(30)
            make.height.equalTo(offset)
            make.width.equalTo(registerImage.snp.width).multipliedBy(0.26/1.0)
            make.bottom.equalTo(userLocation.snp.bottom)
        }
    }
}
