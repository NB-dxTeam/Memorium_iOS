import UIKit
import SnapKit
import SDWebImage
import FirebaseAuth

class SearchUserTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    private var searchLabel: UILabel!
    private var searchContainerView: UIView!
    
    private let userProfileViewModel = UserProfileViewModel()
    private let friendsViewModel = FriendsViewModel()
    private var searchResults: [User] = []
    
    private var searchDebounceTimer: Timer?
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search UserName"
        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        searchBar.backgroundImage = UIImage() // 선 제거
        return searchBar
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SearchUserTableViewCell.self, forCellReuseIdentifier: "userCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchComponents()
        setupTableView()
        backButtonNavigationBar()
        searchBar.delegate = self
        keyBoardHide()
    }

    func setupSearchComponents() {
        searchContainerView = UIView()
        searchContainerView.backgroundColor = .white
        
//        searchLabel = UILabel()
//        searchLabel.text = "검색"
//        searchLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
//        searchLabel.textAlignment = .left
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.init(hex: "#EFEFEF")
            textField.layer.cornerRadius = 15 // 원하는 라디우스 값 설정
            textField.clipsToBounds = true
        }
        
//        searchContainerView.addSubview(searchLabel)
        searchContainerView.addSubview(searchBar)
        
        view.addSubview(searchContainerView)
        
        searchContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(searchBar.snp.bottom)
        }
        
//        searchLabel.snp.makeConstraints { make in
//            make.top.equalToSuperview()
//            make.leading.equalToSuperview().offset(16)
//            make.trailing.equalToSuperview().offset(-16)
//        }
        
        searchBar.snp.makeConstraints { make in
//            make.top.equalTo(searchLabel.snp.bottom).offset(8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.trailing.equalToSuperview().inset(10)
//            make.bottom.equalToSuperview().offset(-10)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupTableView() {
        tableView.register(SearchUserTableViewCell.self, forCellReuseIdentifier: "SearchUserCell")
        tableView.rowHeight = 100
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainerView.snp.bottom) // 컨테이너 뷰의 바로 아래 시작
            make.leading.bottom.trailing.equalToSuperview().inset(10)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.performSearch(with: searchText)
        })
    }

       // MARK: - Functions
    private func performSearch(with searchText: String) {
         guard !searchText.isEmpty else {
             searchResults = []
             tableView.reloadData()
             return
         }

         friendsViewModel.searchUsersByUserName(userName: searchText) { [weak self] users, error in
             DispatchQueue.main.async {
                 if let error = error {
                     print("Error searching users: \(error.localizedDescription)")
                 } else {
                     self?.searchResults = users ?? []
                     self?.tableView.reloadData()
                 }
             }
         }
     }

       // MARK: - TableView Delegate & DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? SearchUserTableViewCell else {
            return UITableViewCell()
        }
        let user = searchResults[indexPath.row]
        cell.configure(with: user, viewModel: friendsViewModel)
        return cell
    }
}
extension SearchUserTableViewController {
    func backButtonNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationItem.hidesBackButton = true
        
        navigationItem.title = "친구 검색"
        
        // 백 버튼 생성
        let backButton = UIButton(type: .system)
        let image = UIImage(systemName: "chevron.left")
        backButton.setBackgroundImage(image, for: .normal)
        backButton.tintColor = UIColor(red: 209/255.0, green: 94/255.0, blue: 107/255.0, alpha: 1)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        
        // 내비게이션 바에 백 버튼 추가
        navigationController?.navigationBar.addSubview(backButton)
        
        // 백 버튼의 위치 조정
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.centerYAnchor.constraint(equalTo: navigationController!.navigationBar.centerYAnchor).isActive = true
        backButton.leadingAnchor.constraint(equalTo: navigationController!.navigationBar.leadingAnchor, constant: 20).isActive = true
    }
    @objc private func backButtonTapped() {
           let tabBarController = MainTabBarView()
           tabBarController.modalPresentationStyle = .fullScreen
           present(tabBarController, animated: true, completion: nil)
       }
}
