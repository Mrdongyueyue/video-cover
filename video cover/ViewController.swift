//
//  ViewController.swift
//  video cover
//
//  Created by 董知樾 on 2022/2/15.
//

import UIKit
import AVKit
import AVFoundation

class ImageCell: UICollectionViewCell {
    var imageView: UIImageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
    }
}

class ViewController: UIViewController {

    @IBOutlet private  weak var imageView: UIImageView!
    @IBOutlet private  weak var slider: UICollectionView!
    @IBOutlet private  weak var layout: UICollectionViewFlowLayout!
    
    @IBOutlet private  weak var sliderPointerView: UIView!
    @IBOutlet private  weak var sliderPointerLeading: NSLayoutConstraint!
    
    var selectCompletion: ((UIImage?) ->())?
    var videoFileUrl: URL?
    
    private var thumbnailImageKeys: [String] = []
    private lazy var imageDictionary: [String : UIImage] = [:]
    
    private var videoAsset: AVAsset!
    private var imageGenerator: AVAssetImageGenerator!
    
    private let queue: DispatchQueue = DispatchQueue.global()
    
    private var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slider.register(ImageCell.self, forCellWithReuseIdentifier: "cell")
        
        sliderPointerView.layer.borderWidth = 1
        sliderPointerView.layer.borderColor = UIColor.orange.cgColor
        sliderPointerView.backgroundColor = UIColor.clear
        
        sliderPointerView.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(sliderPointerViewPanAction(_:)))
        sliderPointerView.addGestureRecognizer(pan)
        
        if let url = videoFileUrl {
            let asset = AVAsset(url: url)
            videoAsset = asset
            imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceBefore = CMTime(value: CMTimeValue(1), timescale: 1000)
            imageGenerator.requestedTimeToleranceAfter = CMTime(value: CMTimeValue(1), timescale: 1000)
            requestThumbnailImages()
            
            let item = AVPlayerItem(asset: videoAsset)
            let player = AVPlayer(playerItem: item)
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect
            view.layer.addSublayer(playerLayer)
            
            self.playerLayer = playerLayer
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = imageView.frame
    }
    
    @IBAction func doneItemDidClick(_ sender: UIBarButtonItem) {
        let offsetSeconds = Double((slider.contentOffset.x - sliderPointerLeading.constant) / slider.contentSize.width) * videoAsset.duration.seconds * 100
        
        queue.async {
            do {
                let cgimage = try self.imageGenerator.copyCGImage(at: CMTime(value: CMTimeValue(offsetSeconds), timescale: 100), actualTime: nil)
                
                let image = UIImage(cgImage: cgimage)
                
                DispatchQueue.main.async {
                    self.selectCompletion?(image)
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.selectCompletion?(nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    func requestThumbnailImages() {
//        let alert = UIAlertController(title: "loading...", message: nil, preferredStyle: .alert)
//        self.present(alert, animated: true, completion: nil)
        print("loading...")
        queue.async {
            // 时长短的增大缩略图取样数量，时长长的减少缩略图取样数量
            let count = CMTimeValue(self.videoAsset.duration.seconds)
            
            for i in 0...count {
                autoreleasepool {
                    do {
                        let cgimage = try self.imageGenerator.copyCGImage(at: CMTime(value: i, timescale: 1), actualTime: nil)
                        
                        if let data = UIImage(cgImage: cgimage).jpegData(compressionQuality: 0.1), let image = UIImage(data: data) {
                            let key = String(format: "thumbnail-key-%d", i)
                            self.thumbnailImageKeys.append(key)
                            self.imageDictionary[key] = image
                        }
                    } catch {
                    }
                }
            }
            DispatchQueue.main.async {
//                alert.dismiss(animated: true, completion: nil)
                print("loading finish")
                self.slider.reloadData()
            }
        }
    }
    /// 滑动手势初始位置偏移量
    private var sliderPointerOffset: CGFloat = 0
    @objc private func sliderPointerViewPanAction(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .possible, .began:
            let location = pan.location(in: sliderPointerView)
            sliderPointerOffset = location.x - 30
            break
            
        case .changed:
            let location = pan.location(in: sliderPointerView)
            var x = sliderPointerView.convert(location, to: self.view).x - sliderPointerOffset
            if x < 0 {
                x = 0
            } else if x > self.view.bounds.width - 60 {
                x = self.view.bounds.width - 60
            }
            sliderPointerLeading.constant = -x
            sliderChanged()
            break
            
        case .ended, .cancelled, .failed:
            sliderPointerOffset = 0
           break
            
        @unknown default:
            break
        }
    }
    
    private func sliderChanged() {
        let offsetSeconds = Double((slider.contentOffset.x - sliderPointerLeading.constant) / slider.contentSize.width) * videoAsset.duration.seconds * 100
        
        playerLayer?.player?.seek(to: CMTime(value: CMTimeValue(offsetSeconds), timescale: 100), toleranceBefore: CMTime(value: CMTimeValue(1), timescale: 1000), toleranceAfter: CMTime(value: CMTimeValue(1), timescale: 1000))
    }
    
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnailImageKeys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let imageCell = cell as? ImageCell {
            imageCell.imageView.image = imageDictionary[thumbnailImageKeys[indexPath.item]]
        }
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        sliderChanged()
    }
}
