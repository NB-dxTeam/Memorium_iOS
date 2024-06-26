//
//  FriendCollectionViewCell.swift
//  dxTimeCapsule
//
//  Created by YeongHo Ha on 3/19/24.
//

import UIKit

class FriendCollectionViewCell: UICollectionViewCell {
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, userNameLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(5)
            make.right.lessThanOrEqualToSuperview().offset(-5)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
    }
    
    func configure(with friend: User) {
        userNameLabel.text = friend.userName
        if let profileImageUrlString = friend.profileImageUrl, let profileImageUrl = URL(string: profileImageUrlString) {
            profileImageView.sd_setImage(with: profileImageUrl, placeholderImage: UIImage(named: "defaultProfileImage"))
        } else {
            profileImageView.image = UIImage(named: "defaultProfileImage") // Use a default image if no URL is provided
        }
    }
}

