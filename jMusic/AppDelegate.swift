//
//  AppDelegate.swift
//  jMusic
//
//  Created by Jota Melo on 27/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import UIKit
import RealmSwift
import iRate
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if SpotifyAPI.Constants.clientID == "" || SpotifyAPI.Constants.clientSecret == "" {
            fatalError("Missing Spotify client ID and client secret in SpotifyAPI.swift")
        }

        if Constants.lastResortAppleMusicToken == "" {
            fatalError("Missing Apple Music JWT from Constants.swift")
        }

        if Date() > Constants.lastResortAppleMusicTokenExpirationDate {
            fatalError("Apple Music JWT expired")
        }
        
        if UserDefaults.standard.object(forKey: "keychainReset") == nil {
            KeychainSwift().clear()
            UserDefaults.standard.set(true, forKey: "keychainReset")
        }
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            Helper.testMode = true
        #endif

        self.setupUI()
        self.setupRealmMigration()
        self.setupiRate()
        
        self.appCoordinator = AppCoordinator(navigationController: BaseNavigationController(), delegate: nil)
        self.appCoordinator?.start()

        self.window = UIWindow()
        self.window?.rootViewController = self.appCoordinator?.navigationController
        self.window?.makeKeyAndVisible()

        return true
    }
    
    func setupUI() {
        
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "Avenir-Book", size: 17) ?? UIFont.systemFont(ofSize: 17)]
        UINavigationBar.appearance().tintColor = UIColor.white
    }
    
    func setupiRate() {
        
        iRate.sharedInstance().onlyPromptIfLatestVersion = true
        iRate.sharedInstance().daysUntilPrompt = 0
        iRate.sharedInstance().eventsUntilPrompt = 2
        iRate.sharedInstance().messageTitle = NSLocalizedString("Rate me on the App Store", comment: "")
        iRate.sharedInstance().message = NSLocalizedString("Are you liking jMusic? Your rating would help a lot! If you have any feedback, please go to About to send me an email and I'll answer you (I can't reply to reviews on the app store... yet)", comment: "")
        iRate.sharedInstance().rateButtonLabel = NSLocalizedString("Sure, I'll rate it!", comment: "")
        iRate.sharedInstance().remindButtonLabel = NSLocalizedString("Not now, but remind me later", comment: "")
        iRate.sharedInstance().cancelButtonLabel = NSLocalizedString("God I hate this...", comment: "")
    }
    
    func setupRealmMigration() {
        
        if Helper.defaultsObject(forKey: "hasSetupjMusicSwift") == nil {
            try? FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
            Helper.set(true, forKey: "hasSetupjMusicSwift")
        }
        
        let config = Realm.Configuration(schemaVersion: 10, migrationBlock: { migration, oldSchemaVersion in
            if oldSchemaVersion < 6 {
                // nothing since we actually deleted the whole thing
            }
            
            if oldSchemaVersion == 6 {
                migration.enumerateObjects(ofType: RealmPlaylist.className(), { oldObject, newObject in
                    newObject?["uuid"] = UUID().uuidString
                })
                
                migration.enumerateObjects(ofType: RealmTrack.className(), { oldObject, newObject in
                    newObject?["uuid"] = UUID().uuidString
                })
                
                migration.enumerateObjects(ofType: RealmSearch.className(), { oldObject, newObject in
                    newObject?["uuid"] = UUID().uuidString
                })
                
                migration.enumerateObjects(ofType: RealmSearchResult.className(), { oldObject, newObject in
                    newObject?["uuid"] = UUID().uuidString
                })
                
                migration.enumerateObjects(ofType: Import.className(), { oldObject, newObject in
                    newObject?["uuid"] = UUID().uuidString
                })
            }
        })
        
        Realm.Configuration.defaultConfiguration = config
        
        _ = try! Realm()
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        NotificationCenter.default.post(name: .jMusicOpenURL, object: nil, userInfo: ["URL": url])
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

