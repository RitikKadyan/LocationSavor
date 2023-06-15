//
//  EditLocationView.swift
//  LocationSaver
//
//  Created by Ritik Kadyan on 6/12/23.
//

import SwiftUI
import CoreLocation
import UIKit

struct EditLocationView: View {
    @Binding var locationName: String
    @Binding var isShowingPopover: Bool
    
    @State private var editedLocationName: String
    
    init(locationName: Binding<String>, isShowingPopover: Binding<Bool>) {
        _locationName = locationName
        _isShowingPopover = isShowingPopover
        _editedLocationName = State(initialValue: locationName.wrappedValue)
    }
    
    var body: some View {
        VStack {
            TextField("Enter Name", text: $editedLocationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Save") {
                locationName = editedLocationName
                isShowingPopover = false
            }
        }
        .padding()
    }
}




struct EditLocationView_Previews: PreviewProvider {
    static var previews: some View {
        let locationName = Binding<String>.constant("Location 1")
        let isShowingPopover = Binding<Bool>.constant(true)
        
        return EditLocationView(locationName: locationName, isShowingPopover: isShowingPopover)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
