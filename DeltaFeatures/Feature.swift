//
//  ExperimentalFeatures.swift
//  Delta
//
//  Created by Riley Testut on 4/5/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import SwiftUI
import Combine

public struct EmptyOptions
{
    public init() {}
}

@propertyWrapper @dynamicMemberLookup
public final class Feature<Options>: _AnyFeature
{
    public let name: LocalizedStringKey
    public let description: LocalizedStringKey?
    
    // Assigned to property name.
    public internal(set) var key: String = ""
    
    // Used for `NotificationUserInfoKey.name` value in .settingsDidChange notification.
    public var settingsKey: Settings.Name {
        return Settings.Name(rawValue: self.key)
    }
    
    public var isEnabled: Bool {
        get {
            let isEnabled = UserDefaults.standard.bool(forKey: self.key)
            return isEnabled
        }
        set {
            self.objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: self.key)
            
            NotificationCenter.default.post(name: .settingsDidChange, object: nil, userInfo: [Settings.NotificationUserInfoKey.name: self.settingsKey, Settings.NotificationUserInfoKey.value: newValue])
        }
    }
    
    public var wrappedValue: some Feature {
        return self
    }
    
    public lazy var projectedValue: ObservedObject<Feature<Options>>.Wrapper = { [unowned self] in
        ObservedObject(initialValue: self.observedFeature ?? self).projectedValue
    }()
    
    private var options: Options
    
    // Track changes to another instance of this feature via key path.
    private weak var observedFeature: Feature<Options>?
    
    public init(name: LocalizedStringKey, description: LocalizedStringKey? = nil, options: Options = EmptyOptions())
    {
        self.options = options
        
        self.name = name
        self.description = description
        
        self.prepareOptions()
    }
    
    // Use `KeyPath` instead of `WritableKeyPath` as parameter to allow accessing projected property wrappers.
    public subscript<T>(dynamicMember keyPath: KeyPath<Options, T>) -> T {
        get {
            options[keyPath: keyPath]
        }
        set {
            guard let writableKeyPath = keyPath as? WritableKeyPath<Options, T> else { return }
            options[keyPath: writableKeyPath] = newValue
        }
    }
}

public extension Feature
{
    var allOptions: [any AnyOption] {
        let features = Mirror(reflecting: self.options).children.compactMap { (child) -> (any AnyOption)? in
            let feature = child.value as? (any AnyOption)
            return feature
        }
        return features
    }
    
    convenience init<Container: FeatureContainer, F: Feature>(_ keyPath: KeyPath<Container, F>)
    {
        let feature = Container.shared[keyPath: keyPath]
        
        self.init(name: feature.name, description: feature.description, options: feature.options)
        
        self.key = feature.key
        self.observedFeature = feature
    }
}

private extension Feature
{
    func prepareOptions()
    {
        // Update option keys + feature
        for case (let key?, let option as any _AnyOption) in Mirror(reflecting: self.options).children
        {
            // Remove leading underscore.
            let sanitizedKey = key.dropFirst()
            option.key = String(sanitizedKey)
            option.feature = self
        }
    }
}
