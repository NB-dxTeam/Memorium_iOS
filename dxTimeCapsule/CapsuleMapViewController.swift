import UIKit
import MapKit
import CoreLocation
import SnapKit
import FirebaseFirestore
import FirebaseAuth

class CapsuleMapViewController: UIViewController {
    let capsuleMaps = MKMapView() // 지도 뷰
    var locationManager = CLLocationManager()
    var currentDetent: String? = nil
    // 타임박스 정보와 태그된 친구들의 정보를 담을 배열
    var timeBoxAnnotationsData = [TimeBoxAnnotationData]()
    var timeBoxes: [TimeBox] = []
    var selectedTimeBoxAnnotationData: TimeBoxAnnotationData?
    private var selectedButton: UIButton?
    lazy var friendsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 80)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(FriendCollectionViewCell.self, forCellWithReuseIdentifier: "FriendCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    // 원래 지도의 중심 위치를 저장할 변수
    private var originalCenterCoordinate: CLLocationCoordinate2D?
    
    private var shouldShowModal = false
    // 버튼을 생성하고 설정하는 클로저
    
    private lazy var allButton: UIButton = {
        let button = UIButton()
        // "AdobeBox_All" 이미지를 allButton에 설정합니다.
        if let image = UIImage(named: "AdobeBox_All")?.resizedImage(newSize: CGSize(width: 70, height: 40)) {
            button.setImage(image, for: .normal)
        }
        configureButtonAppearance(button: button)
        button.addAction(UIAction { [weak self] _ in
            self?.buttonTapped(name: "all")
        }, for: .touchUpInside)
        return button
    }()
    
    lazy var lockedButton: UIButton = {
        let button = UIButton()
        // "AdobeBox_Close" 이미지를 lockedButton에 설정합니다.
        if let image = UIImage(named: "AdobeBox_Close")?.resizedImage(newSize: CGSize(width: 35, height: 35)) {
            button.setImage(image, for: .normal)
        }
        configureButtonAppearance(button: button)
        button.addAction(UIAction { [weak self] _ in
            self?.buttonTapped(name: "locked")
        }, for: .touchUpInside)
        return button
    }()
    
    lazy var openedButton: UIButton = {
        let button = UIButton()
        // "AdobeBox_Open" 이미지를 openedButton에 설정합니다.
        if let image = UIImage(named: "AdobeBox_Open")?.resizedImage(newSize: CGSize(width: 35, height: 35)) {
            button.setImage(image, for: .normal)
        }
        configureButtonAppearance(button: button)
        button.addAction(UIAction { [weak self] _ in
            self?.buttonTapped(name: "opened")
        }, for: .touchUpInside)
        return button
    }()
    
    // 하프모달 버튼
    private lazy var tapDidModal: UIButton = {
        let button = UIButton()
        if let image = UIImage(named: "list")?.resizedImage(newSize: CGSize(width: 25, height: 25)) {
            button.setImage(image, for: .normal)
        }
        button.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 25
        return button
    }()
    
    // 지도 확대 버튼
    private let zoomInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    // 줌 배경
    private let zoomBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        view.layer.cornerRadius = 20
        return view
    }()
    
    // 지도 축소 버튼
    private let zoomOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "minus"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addButtonNavigationBar()
        addSubViews()
        setupZoomControls()
        autoLayouts()
        locationSetting()
        setupMapView()
        buttons()
        updateButtonSelection(allButton)
        selectedButton = allButton
        loadCapsuleInfos(button: .all)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShowModal {
            showModalVC()
        }
    }
    
    private func addSubViews() {
        self.view.addSubview(capsuleMaps)
        self.view.addSubview(tapDidModal)
        self.view.addSubview(zoomBackgroundView)
    }
    private func setupZoomControls() {
        view.addSubview(zoomBackgroundView)
        zoomBackgroundView.addSubview(zoomInButton)
        zoomBackgroundView.addSubview(zoomOutButton)
    }
    private func autoLayouts() {
        capsuleMaps.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }
        
        tapDidModal.snp.makeConstraints { make in
            make.bottom.equalTo(capsuleMaps.snp.bottom).offset(-20)
            make.trailing.equalTo(capsuleMaps.snp.trailing).offset(-20)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
        
        zoomBackgroundView.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.centerY).offset(-50) // 센터보다 위로 조금
            make.width.equalTo(40)
            make.height.equalTo(120)
        }
        
        zoomInButton.snp.makeConstraints { make in
            make.top.equalTo(zoomBackgroundView.snp.top).offset(10)
            make.centerX.equalTo(zoomBackgroundView.snp.centerX)
            make.width.equalTo(zoomBackgroundView.snp.width).multipliedBy(0.6)
            make.height.equalTo(zoomInButton.snp.width)
        }
        
        zoomOutButton.snp.makeConstraints { make in
            make.bottom.equalTo(zoomBackgroundView.snp.bottom).offset(-10)
            make.centerX.equalTo(zoomBackgroundView.snp.centerX)
            make.width.equalTo(zoomBackgroundView.snp.width).multipliedBy(0.6)
            make.height.equalTo(zoomOutButton.snp.width)
        }
    }
    private func buttons() {
        tapDidModal.addTarget(self, action: #selector(modalButton(_:)), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
    }
    // MARK: - Actions
    @objc private func zoomIn() {
        let region = MKCoordinateRegion(center: capsuleMaps.centerCoordinate, span: capsuleMaps.region.span)
        let zoomedRegion = capsuleMaps.regionThatFits(MKCoordinateRegion(center: region.center, span: MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta / 2, longitudeDelta: region.span.longitudeDelta / 2)))
        capsuleMaps.setRegion(zoomedRegion, animated: true)
    }
    
    @objc private func zoomOut() {
        let region = MKCoordinateRegion(center: capsuleMaps.centerCoordinate, span: capsuleMaps.region.span)
        let newLatitudeDelta = min(region.span.latitudeDelta * 2, 180.0)
        let newLongitudeDelta = min(region.span.longitudeDelta * 2, 180.0)
        let zoomedRegion = capsuleMaps.regionThatFits(MKCoordinateRegion(center: region.center, span: MKCoordinateSpan(latitudeDelta: newLatitudeDelta, longitudeDelta: newLongitudeDelta)))
        capsuleMaps.setRegion(zoomedRegion, animated: true)
    }
    
    // 버튼이 눌렸을 때 호출되는 메서드
    private func buttonTapped(name: String) {
        let buttonToSelect: UIButton
        capsuleMaps.removeAnnotations(capsuleMaps.annotations)
        
        let status: CapsuleFilterButtons
        switch name {
        case "all":
            // 'All' 버튼 로직
            loadCapsuleInfos(button: .all)
            buttonToSelect = allButton
            status = .all
            showModalVC()
        case "locked":
            // 'Locked' 버튼 로직
            loadCapsuleInfos(button: .locked)
            buttonToSelect = lockedButton
            status = .locked
            showModalVC()

        case "opened":
            // 'Opened' 버튼 로직
            loadCapsuleInfos(button: .opened)
            buttonToSelect = openedButton
            status = .opened
            showModalVC()
        default:
            return
        }
        NotificationCenter.default.post(name: .capsuleButtonTapped, object: nil, userInfo: ["status": status])
        // 버튼의 선택 상태 업데이트
        updateButtonSelection(buttonToSelect)
        // 현재 선택된 버튼을 저장
        selectedButton = buttonToSelect
    }
    private func updateButtonSelection(_ selectedButton: UIButton) {
        // 모든 버튼을 기본 상태로 리셋
        [allButton, lockedButton, openedButton].forEach {
            $0.backgroundColor = .white.withAlphaComponent(0.75)
            $0.setTitleColor(UIColor.white.withAlphaComponent(0.2), for: .normal) // 필터 "전체보기" 색상
        }
        
        // 선택된 필터 버튼의 스타일을 변경
        selectedButton.backgroundColor = UIColor(hex: "#d65451") // 필터 선택 시 배경 색상
        selectedButton.setTitleColor(.white, for: .normal)
    }
    
    // 버튼의 공통된 외형을 설정하는 함수
    private func configureButtonAppearance(button: UIButton) {
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white.withAlphaComponent(0.8)
        button.layer.cornerRadius = 20
        button.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 80, height: 40))
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension CapsuleMapViewController: CLLocationManagerDelegate {
    func locationSetting() {
        locationManager.delegate = self
        // 배터리에 맞게 권장되는 정확도
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 사용자 위치 권한 요청
        locationManager.requestWhenInUseAuthorization()
        // 위치 업데이트
        locationManager.startUpdatingLocation()
        
    }
    
    // Firestore 쿼리 결과를 처리하는 함수
    private func dataCapsule(documents: [QueryDocumentSnapshot]) {
        let group = DispatchGroup()
        
        var tempTimeBoxes = [TimeBox]()
        var tempAnnotationsData = [TimeBoxAnnotationData]()
        
        for doc in documents {
            let data = doc.data()
            let geoPoint = data["location"] as? GeoPoint
            let timeBox = TimeBox(
                id: doc.documentID,
                uid: data["uid"] as? String ?? "",
                userName: data["userName"] as? String ?? "",
                imageURL: data["imageURL"] as? [String],
                location: geoPoint,
                addressTitle: data["addressTitle"] as? String ?? "",
                address: data["address"] as? String ?? "",
                description: data["description"] as? String,
                tagFriendUid: data["tagFriendUid"] as? [String],
                createTimeBoxDate: Timestamp(date: (data["createTimeBoxDate"] as? Timestamp)?.dateValue() ?? Date()),
                openTimeBoxDate: Timestamp(date: (data["openTimeBoxDate"] as? Timestamp)?.dateValue() ?? Date()),
                isOpened: data["isOpened"] as? Bool ?? false
            )
            
            tempTimeBoxes.append(timeBox)
                    
            // Always enter the group regardless of whether there are friend tags or not.
            group.enter()
            
            if let tagFriendUids = timeBox.tagFriendUid, !tagFriendUids.isEmpty {
                FirestoreDataService().fetchFriendsInfo(byUIDs: tagFriendUids) { [weak self] friendsInfo in
                    defer { group.leave() }
                    guard let self = self, let friendsInfo = friendsInfo, !friendsInfo.isEmpty else { return }
                    
                    let annotationData = TimeBoxAnnotationData(timeBox: timeBox, friendsInfo: friendsInfo)
                    tempAnnotationsData.append(annotationData)
                }
            } else {
                // If there are no friend tags, still add the annotation data with an empty friendsInfo.
                let annotationData = TimeBoxAnnotationData(timeBox: timeBox, friendsInfo: [])
                tempAnnotationsData.append(annotationData)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.timeBoxes = tempTimeBoxes
            // Call the refactored addAnnotations method with tempAnnotationsData.
            self.addAnnotations(with: tempAnnotationsData)
        }
    }
    // 데이터 정보 불러오기
    private func loadCapsuleInfos(button: CapsuleFilterButtons) {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var query: Query
        switch button {
        case .all:
            query = db.collection("timeCapsules").whereField("uid", isEqualTo: userId)
                .order(by: "openTimeBoxDate", descending: false)
            
        case .locked:
            query = db.collection("timeCapsules")
                .whereField("uid", isEqualTo: userId)
                .whereField("isOpened", isEqualTo: false)
        case .opened:
            query = db.collection("timeCapsules").whereField("uid", isEqualTo: userId)
                .whereField("isOpened", isEqualTo: true)
        }
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            print("눌린 버튼: \(button)")
            self?.dataCapsule(documents: documents)
        }
    }
    
}
extension CapsuleMapViewController {
    func showModalVC() {
            let vc = CustomModal()
        
            vc.isModalInPresentation = false
            // CustomModal에서 타임캡슐 선택 시 실행할 클로저 구현
            vc.onCapsuleSelected = { [weak self] latitude, longitude in
                // 지도의 위치를 업데이트하는 메소드 호출
                self?.moveToLocation(latitude: latitude, longitude: longitude)
                if let sheet = vc.sheetPresentationController {
                    DispatchQueue.main.async {
                        sheet.animateChanges {
                            sheet.detents = [.half, .large()]
                            sheet.selectedDetentIdentifier = .half
                            sheet.largestUndimmedDetentIdentifier = .large
                            sheet.prefersGrabberVisible = true
                            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                            sheet.prefersEdgeAttachedInCompactHeight = true
                            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                        }
                    }
                }
            }
            
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.half, .large()]
                sheet.selectedDetentIdentifier = .half
                sheet.largestUndimmedDetentIdentifier = .large
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                
            }
            //vc.isModalInPresentation = true
            vc.modalPresentationStyle = .formSheet
            self.present(vc, animated: true)
        }

    func moveToLocation(latitude: Double, longitude: Double) {
        let adjustedLatitude = latitude
        let adjustedLongitude = longitude
        let location = CLLocationCoordinate2D(latitude: adjustedLatitude, longitude: adjustedLongitude)
        // 셀 탭했을 때, 줌 상태
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 2000, longitudinalMeters: 2000)
        capsuleMaps.setRegion(region, animated: true)
    }
    // 하프 모달 버튼 동작
    @objc func modalButton(_ sender: UIButton) {
        showModalVC()
    }
    // 지도 현재 위치로 이동
    @objc func locationButton(_ sender: UIButton) {
        capsuleMaps.setUserTrackingMode(.follow, animated: true)
           // 적절한 줌 레벨로 조정하기 위해 추가
           let region = MKCoordinateRegion(center: capsuleMaps.userLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
           capsuleMaps.setRegion(region, animated: true)
    }
    
}

// MARK: -MKMapViewDalegate
extension CapsuleMapViewController: MKMapViewDelegate {
    func setupMapView() {
        
        // 대리자를 뷰컨으로 설정
        capsuleMaps.delegate = self
        capsuleMaps.showsCompass = false
        
        // 위치 사용 시 사용자의 현재 위치 표시
        capsuleMaps.showsUserLocation = true
        capsuleMaps.layer.masksToBounds = true
        capsuleMaps.layer.cornerRadius = 0
        
        // 애니메이션 효과가 추가 되어 부드럽게 화면 확대 및 이동
        //capsuleMaps.setUserTrackingMode(.follow, animated: true)
        capsuleMaps.setUserTrackingMode(.followWithHeading, animated: true)
        
        
        let initalLocation = CLLocation(latitude: 35.9333, longitude: 127.9933)
        let regionRadius: CLLocationDistance = 400000
        let coordinateRegion = MKCoordinateRegion(center: initalLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        capsuleMaps.setRegion(coordinateRegion, animated: true)
    }
    
    // 지도를 스크롤 및 확대할 때, 호출 됨. 즉, 지도 영역이 변경될 때 호출
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("지도 위치 변경")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let timeBoxAnnotation = annotation as? TimeBoxAnnotation else { return nil }
        
        let identifier = "CustomAnnotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            print("새 MKMarkerAnnotationView 생성")
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.animatesWhenAdded = true
            annotationView?.glyphImage = UIImage(named: "boximage1")
            annotationView?.glyphTintColor = .white
            annotationView?.markerTintColor = timeBoxAnnotation.timeBoxAnnotationData?.timeBox.isOpened ?? false ? .systemGray4 : .systemRed
            
        } else {
            print("MKMarkerAnnotationView 재사용")
            annotationView?.markerTintColor = timeBoxAnnotation.timeBoxAnnotationData?.timeBox.isOpened ?? false ? .systemGray4 : .systemRed
        }
        
        
        annotationView?.annotation = annotation
        annotationView?.canShowCallout = true
        annotationView?.animatesWhenAdded = true
        annotationView?.glyphImage = UIImage(named: "boximage1")
        annotationView?.glyphTintColor = .white
        annotationView?.markerTintColor = timeBoxAnnotation.timeBoxAnnotationData?.timeBox.isOpened ?? false ? .systemGray4 : .systemRed
        
        if let timeBoxAnnotation = annotation as? TimeBoxAnnotation {
            annotationView?.detailCalloutAccessoryView = configureDetailView(for: timeBoxAnnotation)
        } else {
        }
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? TimeBoxAnnotation {
            self.selectedTimeBoxAnnotationData = annotation.timeBoxAnnotationData
            print("selectedTimeBoxAnnotationData is now set with \(self.selectedTimeBoxAnnotationData?.friendsInfo.count ?? 0) friend(s)")
            DispatchQueue.main.async {
                self.friendsCollectionView.reloadData()
                print("어노테이션이 선택됨: \(annotation)")
            }
        }
        
    }
}

extension CapsuleMapViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = selectedTimeBoxAnnotationData?.friendsInfo.count ?? 0
        print("collectionView:numberOfItemsInSection: \(count) items")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCollectionViewCell", for: indexPath) as? FriendCollectionViewCell,
              let friend = selectedTimeBoxAnnotationData?.friendsInfo[indexPath.row] else {
            print("Error: Unable to dequeue FriendCollectionViewCell or no friend data available")
            return UICollectionViewCell()
        }
        cell.configure(with: friend)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

// MARK: - UISheetPresentationControllerDelegate
extension CapsuleMapViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        guard let detentIdentifier = sheetPresentationController.selectedDetentIdentifier else {
            return
        }
       
    }
}

extension Notification.Name {
    static let capsuleButtonTapped = Notification.Name("capsuleButtonTapped")
}
enum CapsuleFilterButtons {
    case all, locked, opened
}

extension CapsuleMapViewController {
    func addButtonNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationItem.hidesBackButton = true
        
        // 백 버튼 생성
        let backButton = UIButton(type: .system)
        let image = UIImage(systemName: "chevron.left")
        backButton.setBackgroundImage(image, for: .normal)
        backButton.tintColor = UIColor(red: 209/255.0, green: 94/255.0, blue: 107/255.0, alpha: 1)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        // 현재 위치 버튼
        lazy var currentLocationButton: UIButton = {
            let button = UIButton()
            if let image = UIImage(named: "locationicon")?.resizedImage(newSize: CGSize(width: 20, height: 20)) {
                button.setImage(image, for: .normal)
            }
            button.backgroundColor = UIColor.white.withAlphaComponent(1.0)
            button.layer.masksToBounds = true
            button.layer.cornerRadius = 20
            button.addTarget(self, action: #selector(locationButton(_:)), for: .touchUpInside)
            return button
        }()
        
        lazy var buttonsStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [allButton, lockedButton, openedButton])
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.alignment = .center
            stackView.spacing = 20 // 버튼 사이의 간격을 설정합니다.
            return stackView
        }()
        
        // 내비게이션 바에 버튼 추가
        navigationController?.navigationBar.addSubview(backButton)
        navigationController?.navigationBar.addSubview(currentLocationButton)
        navigationController?.navigationBar.addSubview(buttonsStackView)
        
        // 버튼의 위치 조정
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.centerYAnchor.constraint(equalTo: navigationController!.navigationBar.centerYAnchor).isActive = true
        backButton.leadingAnchor.constraint(equalTo: navigationController!.navigationBar.leadingAnchor, constant: 20).isActive = true
        
        
        currentLocationButton.snp.makeConstraints { make in
        currentLocationButton.centerYAnchor.constraint(equalTo: navigationController!.navigationBar.centerYAnchor).isActive = true
        currentLocationButton.trailingAnchor.constraint(equalTo: navigationController!.navigationBar.trailingAnchor, constant: -20).isActive = true
        make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        buttonsStackView.snp.makeConstraints { make in
        buttonsStackView.trailingAnchor.constraint(equalTo: currentLocationButton.leadingAnchor, constant: -20).isActive = true
        buttonsStackView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 20).isActive = true
        buttonsStackView.centerYAnchor.constraint(equalTo: navigationController!.navigationBar.centerYAnchor).isActive = true
//        buttonsStackView.centerXAnchor.constraint(equalTo: navigationController!.navigationBar.centerXAnchor).isActive = true
            // 화면 너비의 5/4로 설정합니다.
//            let screenWidth = UIScreen.main.bounds.width
//            let targetWidth = screenWidth * 4 / 6
//            buttonsStackView.widthAnchor.constraint(equalToConstant: targetWidth).isActive = true
        }
    }
    // 뒤로가기 버튼 동작
    @objc private func backButtonTapped() {
        if let presentedVC = presentedViewController, presentedVC is CustomModal {
            presentedVC.dismiss(animated: true) { [weak self] in
                self?.tabBarController?.selectedIndex = 0
            }
        } else {
            self.tabBarController?.selectedIndex = 0
        }
    }
}
// MARK: - Preview
import SwiftUI

//struct PreView: PreviewProvider {
//    static var previews: some View {
//        CapsuleMapViewController().toPreview()
//    }
//}
#if DEBUG
extension UIViewController {
    private struct Preview: UIViewControllerRepresentable {
            let viewController: UIViewController
            func makeUIViewController(context: Context) -> UIViewController {
                return viewController
            }
            func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            }
        }
        func toPreview() -> some View {
            Preview(viewController: self)
        }
}
#endif

