import SwiftUI
import PhotosUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            // Profile Image Picker
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let image = selectedImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else if let photoURL = authViewModel.userData?["photoURL"] as? String,
                                          let url = URL(string: photoURL) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
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
                            .onChange(of: selectedItem) { _, _ in
                                Task {
                                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        selectedImage = Image(uiImage: uiImage)
                                        selectedImageData = data
                                        
                                        // Upload image to backend
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
                            
                            VStack(alignment: .leading) {
                                if let firstName = authViewModel.userData?["firstName"] as? String,
                                   let lastName = authViewModel.userData?["lastName"] as? String {
                                    Text("\(firstName) \(lastName)")
                                        .font(.headline)
                                    
                                    if let displayName = authViewModel.userData?["displayName"] as? String {
                                        Text("@\(displayName)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding()
                    .navigationTitle("Dashboard")
                    .navigationBarItems(trailing: NavigationLink(destination: SettingsView(authViewModel: authViewModel, userViewModel: userViewModel)) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    })
                }
            }
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundColor(.gray)
    }
}
