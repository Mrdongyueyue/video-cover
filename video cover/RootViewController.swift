//
//  RootViewController.swift
//  video cover
//
//  Created by 董知樾 on 2022/2/15.
//

import UIKit
import UniformTypeIdentifiers

class RootViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var takeVideoCoverButton: UIButton!
    
    private var videoFileUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        takeVideoCoverButton.isEnabled = false
    }
    
    @IBAction func recordVideoDidClick(_ sender: UIButton) {
        let videoPicker = UIImagePickerController()
        videoPicker.sourceType = .camera
        videoPicker.mediaTypes = [UTType.movie.identifier]
        videoPicker.cameraCaptureMode = .video
        videoPicker.delegate = self
        self.present(videoPicker, animated: true, completion: nil)
    }
    
    @IBSegueAction func segueAction(_ coder: NSCoder, sender: Any?, segueIdentifier: String?) -> ViewController? {
        let vc = ViewController(coder: coder)
        vc?.videoFileUrl = videoFileUrl
        vc?.selectCompletion = { [weak self] image in
            self?.imageView.image = image
        }
        return vc
    }
    
}

extension RootViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[.mediaURL] as? URL {
            takeVideoCoverButton.isEnabled = true
            videoFileUrl = url
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
