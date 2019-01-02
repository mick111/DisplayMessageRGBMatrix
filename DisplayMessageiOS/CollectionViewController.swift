//
//  CollectionViewController.swift
//  DisplayMessage
//
//  Created by Michael Mouchous on 02/01/2019.
//  Copyright © 2019 Michael Mouchous. All rights reserved.
//


import UIKit

class CollectionViewController: UICollectionViewController {

    var connectionController : ConnectionController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 60, height: 60)

        collectionView?.collectionViewLayout = layout
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
    }



    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }

    @IBAction func next(_ sender: Any) {
        firstPage += 100
    }
    @IBAction func prev(_ sender: Any) {
        firstPage = max(0,firstPage-100)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath as IndexPath)
        myCell.backgroundColor = UIColor.black
//https://developer.lametric.com/content/apps/icon_thumbs/12200.gif
        guard let imageUrl = URL(string: "https://developer.lametric.com/content/apps/icon_thumbs/\(indexPath.row + firstPage).gif")
            else { return myCell }

        DispatchQueue.global(qos: .userInitiated).async {
            print (imageUrl)
            // Send HTTP GET Request
            // Create URL Request
            var request = URLRequest(url:imageUrl)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) {
                data, response, error in

                // Check for error
                guard error == nil, let data = data else {
                    print("error=\(error!)")
                    return
                }

                DispatchQueue.main.async {
                    let imageView = UIImageView(frame: CGRect(x:0, y:0, width:myCell.frame.size.width, height:myCell.frame.size.height))
                    imageView.image = UIImage(data: data)
                    //imageView.contentMode = UIViewContentMode.scaleAspectFit
                    imageView.animationDuration = 1.0
                    imageView.animationRepeatCount = 0
                    imageView.startAnimating()
                    myCell.addSubview(imageView)
//                    self.collectionView?.reloadData()
                }
            }

            task.resume()
        }


        return myCell
    }

    var firstPage: Int = 12200 { didSet { collectionView?.reloadData() }}

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        print("User tapped on item \(indexPath.row + firstPage)")
        DispatchQueue.main.async {
            try? self.connectionController?.showGIFURL(ID: indexPath.row + self.firstPage)
        }

        //"URLGIF https://developer.lametric.com/content/apps/icon_thumbs/$2.gif $1" > /dev/tcp/192.168.0.44/23735
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
