//
//  ExperimentalFeaturesView.swift
//  Delta
//
//  Created by Riley Testut on 4/5/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import SwiftUI
import Combine

import DeltaFeatures

extension ExperimentalFeaturesView
{
    private class ViewModel: ObservableObject
    {
        @Published
        var sortedFeatures: [AnyFeature]
        
        init()
        {
            // Sort features alphabetically by name.
            self.sortedFeatures = ExperimentalFeatures.shared.allFeatures.sorted { (featureA, featureB) in
                return String(describing: featureA.name) < String(describing: featureB.name)
            }
        }
    }
}

struct ExperimentalFeaturesView: View
{
    @StateObject
    private var viewModel = ViewModel()
    
    var body: some View {
        Form {
            Section(content: {}, footer: {
                Text("These features have been added by contributors to the open-source Delta project on GitHub and are currently being tested before becoming official features. \n\nExpect bugs when using these features.")
                    .font(.subheadline)
            })
            
            ForEach(viewModel.sortedFeatures) { feature in
                ExperimentalFeatureSection(feature: feature)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ExperimentalFeatureSection<T: AnyFeature>: View
{
    @ObservedObject
    var feature: T
    
    var body: some View {
        Section {
            NavigationLink(destination: ExperimentalFeatureView(feature: feature)) {
                HStack {
                    Text(feature.name)
                    Spacer()
                    
                    if feature.isEnabled
                    {
                        Text("On")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }  footer: {
            if let description = feature.description
            {
                Text(description)
            }
        }
    }
}

extension ExperimentalFeaturesView
{
    static func makeViewController() -> UIHostingController<some View>
    {
        let experimentalFeaturesView = ExperimentalFeaturesView()
        
        let hostingController = UIHostingController(rootView: experimentalFeaturesView)
        hostingController.title = NSLocalizedString("Experimental Features", comment: "")
        return hostingController
    }
}

struct ExperimentalFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExperimentalFeaturesView()
        }
    }
}
