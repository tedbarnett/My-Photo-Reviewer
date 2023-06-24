//
//  PhotoDetailsViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 24/06/23.
//

import Foundation

/**
 PhotoDetailsViewModel provides data, state and required backend integration for
 1. Saving/loading audio recorded for the photo
 2. Saving/Loading of location details
 3. Saving/Loading of date details
 */
class PhotoDetailsViewModel: ObservableObject {
    
    // MARK: Public properties
    
    @Published var arePhotoDetailsDownloaded = false
    @Published var photoAudioLocalFileUrl: URL?
    @Published var isRecoringInProgress = false
    @Published var isPlayingAudio = false
    
    var photo: CloudAsset?
    var userProfile: UserProfileModel?
    
    // Application run environment - prod or dev
    var currentEnvironment: Environment = .dev {
        didSet {
            self.storatgeService = FirebaseStorageService(environment: self.currentEnvironment)
        }
    }
    
    // MARK: Private properties
    
    private var storatgeService: FirebaseStorageService?
    
    private var photoId: String? {
        guard let photo = self.photo else {
            return nil
        }
        
        if let applePhotoId = photo.iCloudAssetId {
            if applePhotoId.contains("/") {
                // iCloud photo ids (Ex: 6F2093EF-C398-48B4-901F-858C58E36A1C/L0/001) have `/` char
                // so they need to be replaced with - to prevent Firebase storage reference error
                return applePhotoId.replacingOccurrences(of: "/", with: "-")
            }
            return applePhotoId
        } else if let googlePhotoId = photo.googleDriveFileId {
            return googlePhotoId
        }
        return nil
    }
    
    // Initializer
    
    init() {
        AudioService.instance.delegate = self
    }
    
    // MARK: Public methods
    
    /**
     Connects with Firebase backend to check if user recorded and saved a photo audio for
     the selected photo. If so, it downloads the photo audio content for playback.
     */
    func loadPhotoAudio(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let profile = self.userProfile,
              let photoId = self.photoId,
              let service = self.storatgeService else {
            responseHandler(false)
            return
        }
        
        service.downloadPhotoAudioFor(userId: profile.id, photoId: photoId) { localFileUrl in
            self.isPlayingAudio = false
            self.photoAudioLocalFileUrl = localFileUrl
            self.arePhotoDetailsDownloaded = true
            responseHandler(true)
        }
    }
    
    /**
     Connects to Firebase storage service to save user recording to the backend
     */
    func saveUserRecordingToFirebase(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let audioUrl = AudioService.instance.audioFileUrl,
              let profile = self.userProfile,
              let photoId = self.photoId,
              let service = self.storatgeService else { return }
        
        service.uploadPhotoAudioFor(userId: profile.id, photoId: photoId, audioUrl: audioUrl) { audioFileName in
            guard let fileName = audioFileName else {
                responseHandler(false)
                return
            }
            print("Saved user audio recording with filename: \(fileName)")
            self.loadPhotoAudio(responseHandler: responseHandler)
        }
    }
    
    /**
     Initiates the workflow to start user audio recording for the photo
     */
    func startAudioRecording() {
        AudioService.instance.startUserAudioRecording { didStartRecording in
            self.isRecoringInProgress = didStartRecording
        }
    }
    
    /**
     Attempts to stop user audio recording
     */
    func stopAudioRecording() {
        AudioService.instance.stopUserAudioRecording()
        if self.isRecoringInProgress {
            self.isRecoringInProgress = false
        }
    }
    
    /**
     Attempts to play available photo audio
     */
    func playAudio() {
        guard let url = self.photoAudioLocalFileUrl else { return }
        self.isPlayingAudio = true
        AudioService.instance.playAudio(url)
    }
    
    /**
     Attempts to pause available photo audio
     */
    func pauseAudio() {
        AudioService.instance.pauseAudio()
        self.isPlayingAudio = false
    }
    
    func invalidateViewModel() {
        AudioService.instance.delegate = nil
        self.photoAudioLocalFileUrl = nil
    }
}

// MARK: AudioServiceDelegate delegate methods

extension PhotoDetailsViewModel: AudioServiceDelegate {
    func didFinishPlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didPausePlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didResumePlayingAudio() {
        self.isPlayingAudio = true
    }
    
    func didFailPlayingAudio() {
        self.isPlayingAudio = false
    }
}
