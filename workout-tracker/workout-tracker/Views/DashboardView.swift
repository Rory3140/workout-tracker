import SwiftUI
import PhotosUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Profile Image Picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let image = selectedImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else if let photoURL = authViewModel.userData?["photoURL"] as? String,
                              let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                defaultProfileImage
                            }
                        }
                    } else {
                        defaultProfileImage
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem) {
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                            selectedImageData = data
                            
                            if let uid = authViewModel.user?.uid {
                                userViewModel.uploadProfilePicture(uid: uid, imageData: data) { success in
                                    print(success ? "Profile picture updated successfully" : "Upload failed")
                                }
                            }
                        } else {
                            print("Failed to load image")
                        }
                    }
                }
                
                // Settings Link
                NavigationLink(destination: SettingsView(
                    authViewModel: authViewModel, userViewModel: userViewModel)
                ) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundColor(.gray)
    }
}
