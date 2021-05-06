//
//  Configuration.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation

final class Configuration {
    private(set) var serverUrl: URL?
    var apiURL: URL? {
        return serverUrl?
            .appendingPathComponent("api")
            .appendingPathComponent("v4")
    }
    
    private init(serverUrl: URL?) {
        self.serverUrl = serverUrl
    }
    
    func update(serverUrl: URL) {
        self.serverUrl = serverUrl
    }
    
}

// MARK: - Caching
extension Configuration {
    
    private static let urlCacheKey: String = "configuration_server_url"
    
    static var saved: Configuration {
        return Configuration(serverUrl: UserDefaults.standard.url(forKey: urlCacheKey))
    }
    func saveToCache() {
        UserDefaults.standard.set(serverUrl, forKey: Self.urlCacheKey)
    }
    
}
