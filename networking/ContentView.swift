//
//  ContentView.swift
//  networking
//
//  Created by Jan Přikryl on 01.05.2023.
//

import SwiftUI


class DownloadManager {
    func downloadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let gData = data,
                  let gResponse = response as? HTTPURLResponse,
                  gResponse.statusCode >= 200 && gResponse.statusCode < 300,
                  let image = UIImage(data: gData) else {
                completion(.failure(error ?? NSError(domain: "Unknown error", code: -1, userInfo: nil)))
                return
            }
            
            completion(.success(image))
        }
        .resume()
    }
}

class ViewModel: ObservableObject {
    @Published var image: UIImage?
    
    let downloadManager = DownloadManager()
    
    func downloadImageWithCompletion(from url: URL) {
        downloadManager.downloadImage(from: url) { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async { [weak self] in
                    self?.image = image
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
}

struct ContentView: View {
    @State private var productDetail: ProductDetail? = nil
    @StateObject private var viewModel = ViewModel()
    
    
    
    var body: some View {
        VStack {
            if let detail = productDetail {
                Text("id:  \(detail.id)")
                Text("Product Name: \(detail.name)")
                Text("Price: \(detail.price)")
                Text("Amount: \(detail.amount)")
                Text("Image url: \(detail.image)")
                
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(10)
                }
                
                
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            fetchData()
            
        }
    }
    
    
    func fetchData() {
        guard let url = URL(string: "https://honeststore.eu.pythonanywhere.com/api/get_detail?id=3") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("No data in response: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
                let jsonString2 = jsonString.dropFirst().dropLast()

                if let jsonData = jsonString2.data(using: .utf8) {
                    do {
                        let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                        if let dictionary = json as? [String: Any] {
                            // přístup k hodnotám v JSON objektu
                            let id = dictionary["id"] as? Int ?? 0
                            let name = dictionary["name"] as? String ?? ""
                            let price = dictionary["price"] as? Double ?? 0.0
                            let amount = dictionary["amount"] as? Int ?? 0
                            let image = dictionary["image"] as? String ?? ""
                            
                            let imgUrl = URL(string: image)!
                            viewModel.downloadImageWithCompletion(from: imgUrl)
                            
                            print("Id: \(id), name: \(name), amount: \(amount)")
                            let product = ProductDetail(id:id, name: name, price: price, amount: amount, image: image)
                            self.productDetail = product
                        }
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                } else {
                    print("Invalid JSON string")
                }

            } else {
                print("Invalid data")
            }
            
            
            

        }.resume()
    }
}

struct ProductDetail: Codable {
    var id: Int
    var name: String
    var price: Double
    var amount: Int
    var image: String
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
