import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore

class FirestoreManager: ObservableObject {
    @Published var resources: String = ""
    
    init() {
        fetchResource()
        //fetchAllResources()
    }
    
    func fetchResource() {
        let db = Firestore.firestore()
        db.enableNetwork { (error) in
            let docRef = db.collection("/resourcesApp").document("AA")
            
            docRef.getDocument { (document, error) in
                guard error == nil else {
                    print(docRef.path)
                    print("error getting document", error ?? "")
                    return
                }
                
                if let document = document, document.exists {
                    let data = document.data()
                    if let data = data {
                        print("data", data)
                        self.resources = data["title"] as? String ?? ""
                    }
                }
            }
        }
    }
    func fetchAllResources() {
        let db = Firestore.firestore()
        
        db.collection("resourcesApp").getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID): \(document.data())")
                }
            }
        }
    }
}
