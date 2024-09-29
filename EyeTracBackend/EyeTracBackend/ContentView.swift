import Charts
import SwiftUI
import FirebaseDatabase

struct DataPoint: Identifiable {
    let id = UUID()
    let time: Int
    let value: Double
}

// Updated Data Model
struct DataModel: Identifiable {
    let id: String
    let type: String
    let timestamp: Double
    let patientID: String
    let roomNumber: String
    let discomfortLevel: Int?
}

// Updated ViewModel
class FirebaseDatabaseManager: ObservableObject {
    @Published var dataList = [DataModel]()
    @Published var isLoading = true

    private var ref: DatabaseReference!

    init() {
        ref = Database.database().reference().child("requests")
        fetchData()
    }

    func fetchData() {
        isLoading = true
        ref.observe(.value) { snapshot in
            var newDataList = [DataModel]()

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let value = childSnapshot.value as? [String: Any],
                   let type = value["type"] as? String,
                   let timestamp = value["timestamp"] as? Double,
                   let patientID = value["patientID"] as? String,
                   let roomNumber = value["roomNumber"] as? String {
                    let discomfortLevel = type == "Level of Discomfort" ? value["discomfort_level"] as? Int : nil
                    let dataItem = DataModel(id: childSnapshot.key, type: type, timestamp: timestamp, patientID: patientID, roomNumber: roomNumber, discomfortLevel: discomfortLevel)
                    newDataList.append(dataItem)
                }
            }
            
            DispatchQueue.main.async {
                self.dataList = newDataList
                self.isLoading = false
            }
        }
    }
    
    func deleteItem(withId id: String) {
        ref.child(id).removeValue { error, _ in
            if let error = error {
                print("Error removing item: \(error.localizedDescription)")
            } else {
                print("Item successfully removed")
            }
        }
    }
}

struct GraphView: View {
    let data: [DataPoint]
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Pain Level", point.value)
                )
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Time", point.time),
                    y: .value("Pain Level", point.value)
                )
                .foregroundStyle(.blue)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartXAxisLabel("Time Points")
            .chartYAxisLabel("Pain Level")
            .frame(height: 200)
        }
    }
}

struct GraphsPageView: View {
    let graphData1 = (1...20).map { DataPoint(time: $0, value: Double.random(in: 1...10)) }
    let graphData2 = (1...20).map { DataPoint(time: $0, value: Double.random(in: 1...10)) }
    let graphData3 = (1...20).map { DataPoint(time: $0, value: Double.random(in: 1...10)) }
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    GraphView(data: graphData1, title: "Patient 1")
                    GraphView(data: graphData2, title: "Patient 2")
                    GraphView(data: graphData3, title: "Patient 3")
                }
                .padding()
            }
            .navigationTitle("Pain Level Charts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 50 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}



// Updated DataItemView
struct DataItemView: View {
    let dataItem: DataModel
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(dataItem.type)
                    .font(.headline)
                if dataItem.type == "Level of Discomfort",
                   let discomfortLevel = dataItem.discomfortLevel {
                    Spacer()
                    Text("Level: \(discomfortLevel)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                Spacer()
                Text(formatDate(dataItem.timestamp))
                    .font(.subheadline)
            }
            HStack {
                Text("Patient: \(dataItem.patientID)")
                    .font(.subheadline)
                Spacer()
                Text("Room: \(dataItem.roomNumber)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), .green]), startPoint: .leading, endPoint: .trailing)
                .opacity(Double(offset) / 75.0)
        )
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.width > 0 {
                        offset = gesture.translation.width
                    }
                }
                .onEnded { _ in
                    if offset > 75 {
                        isSwiped = true
                        onDelete()
                    }
                    withAnimation {
                        offset = 0
                    }
                }
        )
    }
    
    func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
}


struct ContentView: View {
    @StateObject var firebaseManager = FirebaseDatabaseManager()
    @State private var showingGraphs = false

    var body: some View {
        NavigationView {
            ZStack {
                if firebaseManager.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(firebaseManager.dataList) { dataItem in
                                DataItemView(dataItem: dataItem) {
                                    firebaseManager.deleteItem(withId: dataItem.id)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nurse Aide")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingGraphs = true
                    }) {
                        Text("Charts")
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingGraphs) {
                GraphsPageView()
            }
        }
    }
    
    func refreshData() async {
        firebaseManager.fetchData()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}


struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).opacity(0.8)
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
