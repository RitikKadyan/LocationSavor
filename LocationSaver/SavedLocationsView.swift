//
//  SavedLocationsView.swift
//  LocationSaver
//
//  Created by Ritik Kadyan on 6/11/23.
//

import Foundation
import SwiftUI
import CoreLocation

struct LocationWrapper: Identifiable, Codable {
    var id = UUID()
    let coordinate: CodableCoordinate
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case coordinate
        case name
    }
    
    init(coordinate: CLLocationCoordinate2D, name: String) {
        self.coordinate = CodableCoordinate(coordinate: coordinate)
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        coordinate = try container.decode(CodableCoordinate.self, forKey: .coordinate)
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate, forKey: .coordinate)
        try container.encode(name, forKey: .name)
    }
}

struct CodableCoordinate: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    init(coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
    
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


struct SavedLocationsView: View {
    @Binding var savedLocations: [LocationWrapper]
    @State private var isShowingCopiedAlert = false
    @State private var copiedCoordinates = ""
    @State private var copiedCoordinatesName = ""
    @State private var isShowingEditPopover = false
    @State private var editingIndex: Int? {
        didSet {
            editingName = editingIndex != nil ? savedLocations[editingIndex!].name : nil
        }
    }
    @State private var editingName: String?

    var body: some View {
        VStack {
            Text("Saved Locations")
                .font(.title)
                .foregroundColor(.white)
            
            List {
                ForEach(savedLocations.indices, id: \.self) { index in
                    HStack {
                        Button(action: {
                            editLocationName(index: index) // Call the editLocationName function
                        }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle(BorderlessButtonStyle())  // Add button style
                        
                        VStack(alignment: .leading) {
                            Text(savedLocations[index].name)
                            Text("\(savedLocations[index].coordinate.latitude), \(savedLocations[index].coordinate.longitude)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            removeLocation(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())  // Add button style
                        Button(action: {
                            openInGoogleMaps(savedLocations[index].coordinate.locationCoordinate)
                        }) {
                            Image(systemName: "safari")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())  // Add button style
                    }
                    .onTapGesture {
                        copyCoordinates(savedLocations[index].coordinate.locationCoordinate, savedLocations[index].name)
                    }
                    
                }
            }
            .background(.blue)
        }
        .padding()
        .background(Color.black)  // Set the background color to black
        .alert(isPresented: $isShowingCopiedAlert) {
            Alert(title: Text("Coordinates Copied for \(copiedCoordinatesName)"), message: Text("Copied: \(copiedCoordinates) )"), dismissButton: .default(Text("OK")))
        }
        .alert("Location Name", isPresented: $isShowingEditPopover, actions: {
            TextField("Enter Name", text: Binding(
                get: { editingName ?? "" },
                set: { editingName = $0 }
            ))
            .foregroundColor(.white)
            .preferredColorScheme(.dark)
            Button("Save", action: {
                if let editingIndex = editingIndex {
                    savedLocations[editingIndex].name = editingName ?? ""
                }
                isShowingEditPopover = false
            })
            .buttonStyle(MyButtonStyle())
            Button("Cancel", role: .cancel) {
                isShowingEditPopover = false
            }
            .buttonStyle(MyButtonStyle())
        })
    }

    private func removeLocation(at index: Int) {
        savedLocations.remove(at: index)
        saveLocations() // Save the updated array after removal
    }
    
    private func saveLocations() {
        do {
            let data = try JSONEncoder().encode(savedLocations)
            UserDefaults.standard.set(data, forKey: "savedLocations")
        } catch {
            print("Failed to encode savedLocations: \(error)")
        }
    }
    
    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: "savedLocations") {
            do {
                savedLocations = try JSONDecoder().decode([LocationWrapper].self, from: data)
            } catch {
                print("Failed to decode savedLocations: \(error)")
            }
        }
    }
    
    private func copyCoordinates(_ coordinate: CLLocationCoordinate2D, _ coordinateName: String) {
        let coordinatesString = "\(coordinate.latitude), \(coordinate.longitude)"
        UIPasteboard.general.string = coordinatesString
        copiedCoordinates = coordinatesString
        copiedCoordinatesName = coordinateName
        isShowingCopiedAlert = true
    }

    private func editLocationName(index: Int) {
        editingIndex = index
        isShowingEditPopover = true
        saveLocations() // Add this line to save the updated name
    }
    
    init(savedLocations: Binding<[LocationWrapper]>) {
        _savedLocations = savedLocations
        loadLocations() // Load the saved locations when the view is initialized
    }

    private func openInGoogleMaps(_ coordinate: CLLocationCoordinate2D) {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let urlString = "comgooglemaps://?center=\(latitude),\(longitude)&zoom=14&views=traffic&q=\(latitude),\(longitude)"
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let webURLString = "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)"
                if let webURL = URL(string: webURLString) {
                    UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
}


struct SavedLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        let locations: [LocationWrapper] = [
            LocationWrapper(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), name: "Location 1"),
            LocationWrapper(coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), name: "Location 2"),
            LocationWrapper(coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), name: "Location 3")
        ]
        return SavedLocationsView(savedLocations: .constant(locations))
    }
}


