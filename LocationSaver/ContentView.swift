//
//  ContentView.swift
//  LocationSaver
//
//  Created by Ritik Kadyan on 6/11/23.
//

import SwiftUI
import CoreLocation


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed with error: \(error.localizedDescription)")
    }
}

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    @AppStorage("savedLocations") var savedLocationsData: Data = Data()
    @State private var isShowingSavedLocations = false
    @State private var savedLocations: [LocationWrapper] = []
    @State private var isShowingNameAlert = false
    @State private var locationName = ""

    var body: some View {
        VStack {
            Button("Save Current Location") {
                if let location = locationManager.location {
                    isShowingNameAlert = true
                }
            }
            .buttonStyle(MyButtonStyle())

            Button("View Saved Locations") {
                isShowingSavedLocations = true
            }
            .buttonStyle(MyButtonStyle())
            .sheet(isPresented: $isShowingSavedLocations) {
                SavedLocationsView(savedLocations: $savedLocations)
            }
        }
        .background(.black)
        .padding()
        .onAppear {
            locationManager.requestLocation()
            loadLocations() // Load the saved locations when the view appears
        }
        .alert("Location Name", isPresented: $isShowingNameAlert, actions: {
            TextField("Enter Name", text: $locationName)
                .foregroundColor(.white)
                .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
            Button("Save", action: { saveLocationWithName() })
                .buttonStyle(MyButtonStyle())
            Button("Cancel", role: .cancel, action: {})
                .buttonStyle(MyButtonStyle())
        })
        .preferredColorScheme(.dark)
        .colorScheme(.dark)
    }

    private func saveLocationWithName() {
        if let location = locationManager.location {
            let locationWrapper = LocationWrapper(coordinate: location, name: locationName)
            savedLocations.append(locationWrapper)
            locationName = ""
            saveLocations() // Add this line to save the new location
        }
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
    
}

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

