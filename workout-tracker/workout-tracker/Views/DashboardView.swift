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
                // A dynamic background that works well in both light and dark mode.
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Card with a dynamic background.
                        HStack {
                            // Profile Image Picker.
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let image = selectedImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else if let cachedImage = userViewModel.loadProfilePictureLocally() {
                                    Image(uiImage: cachedImage)
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
                                        
                                        // Upload image to backend.
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
                            
                            // User Information.
                            VStack(alignment: .leading, spacing: 4) {
                                if let firstName = authViewModel.userData?["firstName"] as? String,
                                   let lastName = authViewModel.userData?["lastName"] as? String {
                                    Text("\(firstName) \(lastName)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.primary)
                                }
                                if let displayName = authViewModel.userData?["displayName"] as? String {
                                    Text("@\(displayName)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                        }
                        .padding()
                        // Use a dynamic color that adjusts for dark mode.
                        //I want to change things here as I dont want the pill around the information
                        //I also think this is where Ill center the info
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Additional dashboard content can be placed here.
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
//            .navigationTitle("Dashboard")
            .navigationBarItems(leading: NavigationLink(destination: SettingsView(authViewModel: authViewModel, userViewModel: userViewModel)) {
                Text("LiftSync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("OrangeAccent"))
            })
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView(authViewModel: authViewModel, userViewModel: userViewModel)) {
                Image(systemName: "gearshape")
                    .imageScale(.large)
                    .foregroundColor(Color("OrangeAccent"))
            })
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
