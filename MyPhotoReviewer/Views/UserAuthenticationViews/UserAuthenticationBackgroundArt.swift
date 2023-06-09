//
//  UserAuthenticationBackgroundArt.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/04/23.
//

import SwiftUI

struct UserAuthenticationBackgroundArt: View {
    var body: some View {
        VStack {
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.black300)
                .rotationEffect(.degrees(-25))
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.7)
                .opacity(0.3)
            
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.black300)
                .rotationEffect(.degrees(20))
                .frame(width: UIScreen.main.bounds.width * 0.5, height: UIScreen.main.bounds.height * 0.5)
                .opacity(0.3)
                .padding(.bottom, 100)
        }
    }
}
