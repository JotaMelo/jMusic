//
//  Constants.swift
//  jMusic
//
//  Created by Jota Melo on 07/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

struct Constants {
    static let tableCellHeight = 50
    static let userAcceptedFirstNotificationDialogDefaultsKey = "userAcceptedFirstNotificationDialogDefaultsKey"
    static let currentImportCollectionID = "currentImportCollectionID"
    static let cloudKitMatchRecordType = "Match"
    static let cloudKitErrorReportRecordType = "TrackErrorReport"
    
    static let lastResortAppleMusicToken = ""
    static let lastResortAppleMusicTokenExpirationDate = Date(timeIntervalSince1970: 0)
}

extension Notification.Name {
    static let jMusicOpenURL = Notification.Name("jMusicOpenURLNotification")
}

struct Colors {
    static let defaultNavigationBarBackgroundColor = #colorLiteral(red: 0.3294117647, green: 0.7803921569, blue: 0.9882352941, alpha: 1)
    static let inProgressNavigationBarBackgrondColor = #colorLiteral(red: 1, green: 0.5882352941, blue: 0, alpha: 1)
    static let doneNavigationBarBackgroundColor = #colorLiteral(red: 0.2666666667, green: 0.8588235294, blue: 0.368627451, alpha: 1)
    static let segmentedControlSelectedColor = #colorLiteral(red: 0.5058823529, green: 0.5960784314, blue: 0.6745098039, alpha: 1)
    static let segmentedControlDeselectedColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
    static let radioButtonSelectedColor = #colorLiteral(red: 0.5058823529, green: 0.5960784314, blue: 0.6745098039, alpha: 1)
    static let radioButtonDeselectedColor = #colorLiteral(red: 0.8078431373, green: 0.862745098, blue: 0.9098039216, alpha: 1)
    static let contentTextColor = #colorLiteral(red: 0.3568627451, green: 0.4352941176, blue: 0.5058823529, alpha: 1)
    static let errorColor = #colorLiteral(red: 1, green: 0.07450980392, blue: 0, alpha: 1)
}
