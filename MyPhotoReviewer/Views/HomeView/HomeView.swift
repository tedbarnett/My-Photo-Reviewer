//
//  HomeView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 22/04/23.
//

import SwiftUI

/**
 HomeView is the main view shown to the user after successful user authentication.
 It presents UI/UX for user to select source of images (Google drive, Apple iCloud, etc), presents
 list of images and their preview.
 
 It also provides the tools for adding details to the image like location,date, time, audio annotation, etc.
 */
struct HomeView: View {
    
    // MARK: Private properties
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    
    @StateObject private var authenticationViewModel = UserAuthenticationViewModel()
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var shouldShowFolderSelectionView = false
    @State private var shouldShowPhotoDetails = false
    @State private var selectedPhoto: CloudAsset?
    
    // MARK: User interface
    
    var body: some View {
        NavigationView {
            ZStack {
                
                // Background
                Color.black900
                    .ignoresSafeArea()
                
                // Content View
                VStack {
                    HStack {
                        
                        // Welcome text
                        HStack(alignment: .center, spacing: 3) {
                            Text(NSLocalizedString("Welcome back", comment: "Photo reviewer view - welcome title"))
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color.offwhite100)
                            Text("\(self.userProfile.name)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.blue500)
                        }
                        Spacer()
                        
                        // Logout button
                        Button(action: {
                            self.overlayContainerContext.shouldShowProgressIndicator = true
                            self.authenticationViewModel.logutUser { didLogoutSuccessfully in
                                self.overlayContainerContext.shouldShowProgressIndicator = false
                                guard didLogoutSuccessfully else {
                                    return
                                }
                                self.userProfile.isAuthenticated = false
                            }
                        }) {
                            Image(systemName: "power.circle.fill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .tint(Color.blue500)
                                .frame(width: 30, height: 30)
                        }
                    }
                    .padding(.horizontal, UIDevice.isIpad ? 40 : 16)
                    
                    Spacer()
                    
                    // Displaying media source selection options, if there are no user photos/albums
                    if !self.userProfile.didAllowPhotoAccess {
                        VStack(alignment: .center, spacing: 24) {
                            Text(NSLocalizedString(
                                "Please select source for your photos from the options listed below",
                                comment: "Home view - Media source selection description")
                            )
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.offwhite100)
                            
                            if UIDevice.isIpad {
                                HStack(alignment: .center, spacing: 40) {
                                    ForEach(MediaSource.allCases, id: \.self) { mediaSource in
                                        MediaSourceSelectionButton(
                                            mediaSource: mediaSource,
                                            width: UIScreen.main.bounds.width * 0.2,
                                            tapActionHandler: { mediaSource in
                                                self.userProfile.mediaSource = mediaSource
                                                self.viewModel.presentMediaSelectionConsent(for: mediaSource) { didAllow in
                                                    self.userProfile.didAllowPhotoAccess = didAllow
                                                    self.loadCloudAssets()
                                                }
                                            }
                                        )
                                    }
                                }
                            } else {
                                VStack(alignment: .center, spacing: 24) {
                                    ForEach(MediaSource.allCases, id: \.self) { mediaSource in
                                        MediaSourceSelectionButton(
                                            mediaSource: mediaSource,
                                            width: UIScreen.main.bounds.width * 0.4,
                                            tapActionHandler: { mediaSource in
                                                self.userProfile.mediaSource = mediaSource
                                                self.viewModel.presentMediaSelectionConsent(for: mediaSource) { didAllow in
                                                    self.userProfile.didAllowPhotoAccess = didAllow
                                                    self.loadCloudAssets()
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Displaying user photos with details, if user photos/album details are saved in database
                    else if !self.viewModel.photos.isEmpty {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: self.viewModel.photoGridColumns, spacing: 16) {
                                ForEach(self.viewModel.photos, id: \.self) { photo in
                                    PhotoView(
                                        photo: photo,
                                        width: self.viewModel.photoGridColumnWidth,
                                        height: self.viewModel.photoGridColumnWidth
                                    )
                                    .onTapGesture {
                                        photo.isDownloaded = false
                                        self.selectedPhoto = photo
                                        self.shouldShowPhotoDetails = true
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    // Change folder button
                    if let mediaSource = self.userProfile.mediaSource {
                        Button(
                            action: {
                                if mediaSource == .iCloud {
                                    self.viewModel.presentICloudPhotoPicker()
                                } else if mediaSource == .googleDrive,
                                    let selectedFolders = self.viewModel.selectedFolders,
                                    !selectedFolders.isEmpty {
                                    self.shouldShowFolderSelectionView = true
                                }
                            },
                            label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                        .frame(height: 40)
                                        .padding(.horizontal, 16)
                                    Text(NSLocalizedString("Change Photo Selection", comment: "Home view - Change photo selection"))
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.white)
                                }
                            }
                        )
                        
                    }
                }
                .padding(.top, UIDevice.isIpad ? 40 : 20)
                
                // Link to photo details view
                NavigationLink(
                    destination:
                        PhotoDetailsView(
                            photos: self.viewModel.photos,
                            selectedPhoto: self.selectedPhoto
                        )
                        .navigationBarHidden(true)
                    ,
                    isActive: self.$shouldShowPhotoDetails
                ) { EmptyView() }
            }
        }
        .onAppear {
            self.initializeViewModels()
            self.loadUserDetails()
        }
        .onChange(of: self.viewModel.shouldShowProgressIndicator) { shouldShowProgressIndicator in
            self.overlayContainerContext.shouldShowProgressIndicator = shouldShowProgressIndicator
        }
        .onChange(of: self.viewModel.shouldShowFolderSelectionView) { shouldShow in
            self.shouldShowFolderSelectionView = shouldShow
        }
        .sheet(isPresented: self.$shouldShowFolderSelectionView) {
            FolderSelectionView(
                folders: self.viewModel.folders,
                delegate: self
            )
        }
    }
    
    // MARK: Private methods
    
    private func initializeViewModels() {
        self.viewModel.currentEnvironment = self.appContext.currentEnvironment
        self.viewModel.userProfile = self.userProfile
        self.viewModel.loadGoogleDriveFoldersFromDatabaseIfAny()
        self.authenticationViewModel.userProfile = self.userProfile
    }
    
    private func loadUserDetails() {
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.loadUserDetailsFromDatabase { didLoadDetails in
            self.overlayContainerContext.shouldShowProgressIndicator = false
            self.loadCloudAssets()
        }
    }
    
    private func loadCloudAssets() {
        guard let mediaSource = self.userProfile.mediaSource else { return }
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.downloadCloudAssets(for: mediaSource) { _ in
            self.overlayContainerContext.shouldShowProgressIndicator = false
        }
    }
}

// MARK: FolderSelectionViewDelegate delegate methods

extension HomeView: FolderSelectionViewDelegate {
    func didCancelFolderSelection() {
        self.shouldShowFolderSelectionView = false
    }
    
    func didChangeFolderSelection(selectedFolders: [CloudAsset]) {
        self.shouldShowFolderSelectionView = false
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.downloadPhotosFromFolders(selectedFolders) { didLoadPhotos in
            self.overlayContainerContext.shouldShowProgressIndicator = false
        }
    }
}
