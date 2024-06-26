//
//  PostUploadView.swift
//  dxTimeCapsule
//
//  Created by t2023-m0031 on 3/13/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct PostUploadView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    @State private var showPhotoPicker: Bool = false
    @State private var currentUser: User?
    @State private var friends: [User] = []
    private var viewModel = FriendsViewModel()
    
    
    // MARK: - Body
    
    var body: some View {
        NavigationView{
            VStack(alignment: .leading) {
                TextField("What's on your mind?",text: .constant(""),axis: .vertical)
                    .padding(.horizontal)
                
                HStack(spacing: 30) {
                    Button(action: {
                        showPhotoPicker.toggle()
                    }, label: {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .foregroundStyle(.green)
                    })
                    
                    Button(action: {}, label: {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.blue)
                    })
                    
                    Button(action: {}, label: {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(.yellow)
                    })
                    
                    Button(action: {}, label: {
                        Image("pin")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.red)
                    })
                    
                    Button(action: {}, label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(Color(.darkGray))
                    })
                    
                }
                .padding(.top, 50)
                .padding(.bottom, 300)
                .padding(.horizontal)
                
            }
            .navigationBarTitle("Create Post", displayMode: .automatic) // 네비게이션 바 타이틀 추가
        }
    }
}

