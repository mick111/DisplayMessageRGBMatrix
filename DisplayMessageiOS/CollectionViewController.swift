//
//  CollectionViewController.swift
//  DisplayMessage
//
//  Created by Michael Mouchous on 02/01/2019.
//  Copyright © 2019 Michael Mouchous. All rights reserved.
//


import UIKit
class CollectionViewCell: UICollectionViewCell {
    @IBOutlet var activity: UIActivityIndicatorView?
    @IBOutlet var imageView: UIImageView? { didSet {
        imageView?.layer.magnificationFilter = CALayerContentsFilter.nearest
        }}
    @IBOutlet var label: UILabel?
    var controller: CollectionViewController?
    var imageNum: Int = 0
    var url: URL? {
        didSet {
            guard let url = url else { return }
            let imageNum = self.imageNum
            self.activity?.startAnimating()
            URLSession.shared.dataTask(with: url) {
                (data: Data?, response:URLResponse?, error:Error?) in
                
                guard let url = response?.url else { return }
                // Check for error
                guard error == nil, let data = data else {
                    print("error=\(error!.localizedDescription)")
                    DispatchQueue.main.async {
                        self.label?.text = error!.localizedDescription
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if response!.url!.absoluteString.contains(".gif") {
                        if let image = UIImage.gifImageWithData(data) {
                            print("OK >>> ",url)
                            self.activity?.stopAnimating()
                            self.controller?.images[imageNum] = (image, url)
                            self.imageView?.image = image
                        } else {
                            // This will trigger the download of the PNG file
                            self.url = URL(string:url.absoluteString.replacingOccurrences(of: ".gif", with: ".png"))
                        }
                    } else {
                        if let image = UIImage(data:data) {
                            print("OK >>> ",url)
                            self.controller?.images[imageNum] = (image, url)
                            self.imageView?.image = image
                        } else {
                            self.controller?.images[imageNum] = nil
                        }
                        self.activity?.stopAnimating()
                    }
                }
                }.resume()
        }
    }
}

class CollectionViewController: UICollectionViewController {
    
    var connectionController : ConnectionController?
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 500
    }
    
    @IBAction func next(_ sender: Any) {
        firstPage += 500
    }
    @IBAction func prev(_ sender: Any) {
        firstPage = max(0, firstPage-500)
    }
    
    
    var firstPage: Int = 0 { didSet {
        collectionView?.reloadData()
        title = "\(firstPage)"
        }}
    
    
    var images = [Int:(UIImage, URL)?]()
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath as IndexPath) as! CollectionViewCell
        
        let imageNum = indexPath.row + firstPage
        myCell.label?.text = "\(imageNum)"
        myCell.imageView?.image = nil
        myCell.imageNum = imageNum
        myCell.controller = self
        myCell.backgroundColor = UIColor.red.withAlphaComponent(collectionView.indexPathsForSelectedItems?.first == indexPath ? 1 : 0)
        if let image = self.images[imageNum] {
            myCell.imageView?.image = image?.0
            myCell.activity?.stopAnimating()
            return myCell
        }
        let imageUrl = URL(string: "https://developer.lametric.com/content/apps/icon_thumbs/\(imageNum).gif")!
        myCell.url = imageUrl
        return myCell
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        print("User tapped on item \(indexPath.row + firstPage)")
        guard let url = images[indexPath.row + self.firstPage]??.1 else { return }
        DispatchQueue.main.async {
            try? self.connectionController?.showGIFURL(url: url)
            for cell in collectionView.visibleCells {
                cell.backgroundColor = UIColor.red.withAlphaComponent(0)
            }
            collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor.red.withAlphaComponent(1)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
