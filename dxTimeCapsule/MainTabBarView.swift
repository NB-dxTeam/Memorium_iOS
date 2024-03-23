import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class MainTabBarView: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTabs()
        self.delegate = self
        
        // 앱 시작 시 친구 요청을 확인.

        updateFriendRequestBadge()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateFriendRequestBadge), name: NSNotification.Name("UpdateFriendRequestBadge"), object: nil)

//        // NotificationCenter Observer 추가 - 우경
//        NotificationCenter.default.addObserver(self, selector: #selector(returnToHome), name: NSNotification.Name("ReturnToHome"), object: nil)
    }
    
//    @objc func returnToHome() {
//        // 첫 번째 탭(홈 화면)으로 이동합니다. - 우경
//        self.selectedIndex = 0
//    }
    
    private func setupTabs() {
        let homeViewController = UINavigationController(rootViewController: HomeViewController())
        
        let searchModalTableViewController = UINavigationController(rootViewController: CapsuleMapViewController())
        
//        let postUploadViewHostingController = UIHostingController(rootView: PostUploadView())
        let postUploadNavigationController = UINavigationController(rootViewController: LocationMapkitViewController())

        let notificationViewController = UINavigationController(rootViewController: FriendsRequestViewController())
        let profileViewController = UINavigationController(rootViewController: UserProfileViewController())
        
        homeViewController.tabBarItem = UITabBarItem(title: nil, image: resizeImage(imageName: "Light=Home_Deselect", targetSize: CGSize(width: 24, height: 24)), selectedImage: resizeImage(imageName: "Light=Home_Select", targetSize: CGSize(width: 24, height: 24)))
        homeViewController.tabBarItem.tag = 0
        
        searchModalTableViewController.tabBarItem = UITabBarItem(title: nil, image: resizeImage(imageName: "Light=Search_Deselect", targetSize: CGSize(width: 24, height: 24)), selectedImage: resizeImage(imageName: "Light=Search_Select", targetSize: CGSize(width: 24, height: 24)))
        searchModalTableViewController.tabBarItem.tag = 1

        
        postUploadNavigationController.tabBarItem = UITabBarItem(title: nil, image: resizeImage(imageName: "Light=Write_Deselect", targetSize: CGSize(width: 24, height: 24)), selectedImage: resizeImage(imageName: "Light=Write_Select", targetSize: CGSize(width: 24, height: 24)))
        postUploadNavigationController.tabBarItem.tag = 2
        
        notificationViewController.tabBarItem = UITabBarItem(title: nil, image: resizeImage(imageName: "Light=Activity_Deselect", targetSize: CGSize(width: 24, height: 24)), selectedImage: resizeImage(imageName: "Light=Activity_Select", targetSize: CGSize(width: 24, height: 24)))
        notificationViewController.tabBarItem.tag = 3
        
        profileViewController.tabBarItem = UITabBarItem(title: nil, image: resizeImage(imageName: "Light=Profile_Deselect", targetSize: CGSize(width: 24, height: 24)), selectedImage: resizeImage(imageName: "Light=Profile_Select", targetSize: CGSize(width: 24, height: 24)))
        profileViewController.tabBarItem.tag = 4

        
        let viewControllers = [homeViewController, searchModalTableViewController, postUploadNavigationController, notificationViewController, profileViewController]
        
        self.viewControllers = viewControllers
        self.tabBar.tintColor = UIColor(hex: "#C82D6B")
        self.tabBar.backgroundColor = .white
    }
    
    func updateNotificationBadge(with count: Int) {
        DispatchQueue.main.async {
            if count > 0 {
                // 친구 요청이 있을 경우, 숫자를 배지에 표시
                self.viewControllers?[3].tabBarItem.badgeValue = "\(count)"
            } else {
                // 친구 요청이 없을 경우, 배지를 숨깁니다.
                self.viewControllers?[3].tabBarItem.badgeValue = nil
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == 0 { // 홈 버튼의 태그가 0이라고 가정합니다.
            // 현재 선택된 뷰 컨트롤러를 가져옵니다.
            guard let currentViewController = selectedViewController as? UINavigationController else {
                return true
            }
            
            // 홈 뷰 컨트롤러를 새로 생성합니다.
            let newHomeViewController = HomeViewController()
            newHomeViewController.tabBarItem = UITabBarItem(title: nil, image: resizeImage(imageName: "Light=Home_Deselect", targetSize: CGSize(width: 24, height: 24)), selectedImage: resizeImage(imageName: "Light=Home_Select", targetSize: CGSize(width: 24, height: 24)))
            newHomeViewController.tabBarItem.tag = 0 // 홈 버튼의 태그 설정
            newHomeViewController.tabBarItem.badgeValue = viewController.tabBarItem.badgeValue // 배지 값 복사
            
            // 탭 바 아이템의 틴트 색상 변경
            tabBarController.tabBar.tintColor = UIColor(hex: "#C82D6B")
            
            // 홈 버튼이 선택되었을 때의 이미지 설정
            viewController.tabBarItem.selectedImage = resizeImage(imageName: "Light=Home_Select", targetSize: CGSize(width: 24, height: 24))
            
            // 현재 선택된 뷰 컨트롤러를 홈 뷰 컨트롤러로 교체합니다.
            currentViewController.setViewControllers([newHomeViewController], animated: false)
            
            return false // 홈 버튼을 눌렀을 때 탭 바의 선택을 변경하지 않습니다.
        }
        return true
    }




    func resizeImage(imageName: String, targetSize: CGSize) -> UIImage? {
        guard let image = UIImage(named: imageName) else { return nil }
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resizedImage
    }
    
    @objc func updateFriendRequestBadge() {
        // 현재 로그인한 사용자의 UID를 가져옵니다.
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        // Firestore에서 현재 사용자의 friendRequestsReceived 필드를 조회합니다.
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).getDocument { [weak self] (document, error) in
            if let error = error {
                // 오류가 발생했을 경우, 콘솔에 오류를 출력합니다.
                print("Error fetching friend requests: \(error)")
                return
            }
            
            if let document = document, document.exists {
                // friendRequestsReceived 필드에서 친구 요청의 수를 가져옵니다.
                let friendRequestsReceived = document.get("friendRequestsReceived") as? [String: Timestamp] ?? [:]
                let friendRequestCount = friendRequestsReceived.count
                
                // 친구 요청의 수를 바탕으로 알림 배지를 업데이트합니다.
                DispatchQueue.main.async {
                    self?.updateNotificationBadge(with: friendRequestCount)
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    

}

