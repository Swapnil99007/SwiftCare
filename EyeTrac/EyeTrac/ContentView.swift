import SwiftUI
import UIKit
import Firebase
import FirebaseDatabase

struct ContentView: View {
    let buttonTitles = ["Medication", "Restroom", "Lights", "Water", "Food", "Level of Discomfort"]
    let buttonIcons = ["pills", "restroom", "light", "water", "food", "discomfort"]
    @State private var showingDiscomfortPopup = false
    
    @State private var patientID = "P3824" // Example patient ID
    @State private var roomNumber = "301" // Example room number
    
    @State private var showingAdminPopup = false
    @State private var nurseContact = "" // Example nurse contact
    @State private var tempPatientID = ""
    @State private var tempRoomNumber = ""
    @State private var tempNurseContact = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.2, alpha: 1)), Color(#colorLiteral(red: 0.05, green: 0.05, blue: 0.1, alpha: 1))]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 100)
                    
                    // Call button
                    // Call button
                    Button(action: {
                        makePhoneCall(phoneNumber: nurseContact)
                    }) {
                        Text("Call")
                            .font(.custom("Avenir-Heavy", size: geometry.size.width * 0.08))
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.height / 4 - 80)
                            .background(Color(#colorLiteral(red: 0.6765594482, green: 0, blue: 0.1631491482, alpha: 1)))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Call Nurse")
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 6 square buttons in 2 rows, 3 each
                    VStack(spacing: 50) {
                        ForEach(0..<2) { row in
                            HStack(spacing: 20) {
                                ForEach(0..<3) { col in
                                    let index = row * 3 + col
                                    createSquareButton(title: buttonTitles[index], icon: buttonIcons[index], size: (geometry.size.width - 80) / 3, screenSize: geometry.size) {
                                        if index == 5 { // "Level of Discomfort" button
                                            showingDiscomfortPopup = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: geometry.size.height / 3 * 2 - 80)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 100)
                }
                    .accessibilityElement(children: .contain)
                    .accessibilityHidden(showingDiscomfortPopup || showingAdminPopup)
                    
                    if showingAdminPopup {
                        AdminPopup(isPresented: $showingAdminPopup, patientID: $patientID, roomNumber: $roomNumber, nurseContact: $nurseContact)
                            .accessibilityElement(children: .contain)
                    }
                    
                    if showingDiscomfortPopup {
                        DiscomfortPopup(isPresented: $showingDiscomfortPopup, sendRequest: sendRequest)
                            .accessibilityElement(children: .contain)
                    }
                }
                .accessibilityElement(children: .contain)
        }
    }
    
    func createSquareButton(title: String, icon: String, size: CGFloat, screenSize: CGSize, action: @escaping () -> Void) -> some View {
        Button(action: {
            if title != "Level of Discomfort" {
                sendRequest(type: title)
            }
            action()
        }) {
            VStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.4, height: size * 0.4)
                Text(title)
                    .font(.custom("Avenir-Medium", size: min(screenSize.width, screenSize.height) * 0.05))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: size, height: size)
            .background(Color(#colorLiteral(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)))
            .foregroundColor(Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
    }
    func sendRequest(type: String, discomfortLevel: Int? = nil) {
        let ref = Database.database().reference()
        let requestRef = ref.child("requests").childByAutoId()
        
        let timestamp = ServerValue.timestamp()
        
        var requestData: [String: Any] = [
            "patientID": patientID,
            "roomNumber": roomNumber,
            "type": type,
            "timestamp": timestamp
        ]
        
        if let level = discomfortLevel {
            requestData["discomfort_level"] = level
        }
        
        requestRef.setValue(requestData) { error, _ in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
            } else {
                print("Request sent successfully: \(type)")
            }
        }
    }
    
    func makePhoneCall(phoneNumber: String) {
        if let phoneURL = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        }
    }
}

struct DiscomfortPopup: View {
    @Binding var isPresented: Bool
    var sendRequest: (String, Int) -> Void
    
    func buttonColor(for number: Int) -> Color {
        let hue = 0.12 - (Double(number - 1) / 9.0) * 0.12
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Please register your discomfort level")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        ForEach(0..<5) { row in
                            HStack(spacing: 40) {
                                ForEach(1...2, id: \.self) { col in
                                    let buttonNumber = row * 2 + col
                                    Button(action: {
                                        sendRequest("Level of Discomfort", buttonNumber)
                                        isPresented = false
                                    }) {
                                        VStack {
                                            Text("\(buttonNumber)")
                                                .font(.custom("Avenir-Bold", size: geometry.size.width * 0.06))
                                        }
                                        .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                                        .background(buttonColor(for: buttonNumber))
                                        .foregroundColor(.white)
                                        .cornerRadius(geometry.size.width * 0.15)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                    }
                                    .accessibilityLabel("Discomfort level \(buttonNumber)")
                                }
                            }
                        }
                    }
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.custom("Avenir-Medium", size: 22))
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width * 0.4, height: 60)
                    .background(Color.gray)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.9)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct AdminPopup: View {
    @Binding var isPresented: Bool
    @Binding var patientID: String
    @Binding var roomNumber: String
    @Binding var nurseContact: String
    @State private var tempPatientID: String
    @State private var tempRoomNumber: String
    @State private var tempNurseContact: String
    
    init(isPresented: Binding<Bool>, patientID: Binding<String>, roomNumber: Binding<String>, nurseContact: Binding<String>) {
        self._isPresented = isPresented
        self._patientID = patientID
        self._roomNumber = roomNumber
        self._nurseContact = nurseContact
        self._tempPatientID = State(initialValue: patientID.wrappedValue)
        self._tempRoomNumber = State(initialValue: roomNumber.wrappedValue)
        self._tempNurseContact = State(initialValue: nurseContact.wrappedValue)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Admin Controls")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(.black)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Text("Patient ID:")
                                .font(.custom("Avenir-Medium", size: 18))
                                .foregroundColor(.black)
                            TextField("", text: $tempPatientID)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        HStack {
                            Text("Room Number:")
                                .font(.custom("Avenir-Medium", size: 18))
                                .foregroundColor(.black)
                            TextField("", text: $tempRoomNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        HStack {
                            Text("Nurse Contact:")
                                .font(.custom("Avenir-Medium", size: 18))
                                .foregroundColor(.black)
                            TextField("", text: $tempNurseContact)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    }
                    
                    Button("Save") {
                        patientID = tempPatientID
                        roomNumber = tempRoomNumber
                        nurseContact = tempNurseContact
                        isPresented = false
                    }
                    .font(.custom("Avenir-Medium", size: 22))
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width * 0.4, height: 60)
                    .background(Color(#colorLiteral(red: 0.6765594482, green: 0, blue: 0.1631491482, alpha: 1))) // Same color as call button
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .frame(width: geometry.size.width * 0.9)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .foregroundColor(.black)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
