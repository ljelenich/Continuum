//
//  AddPostTableViewController.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import UIKit
import Photos

class AddPostTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - Outlets
    @IBOutlet weak var captionTextField: UITextField!
    
    var image: UIImage?
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Add Post"
    }

    //MARK: - Actions
    @IBAction func addPostButtonTapped(_ sender: Any) {
        guard let image = image,
              let caption = captionTextField.text,
              !caption.isEmpty else { return }
        PostController.shared.createPostWith(photo: image, caption: caption) { (post) in
            
        }
        captionTextField.text = ""
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.tabBarController?.selectedIndex = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPhotoPickerVC" {
            let destinationVC = segue.destination as? ImagePickerViewController
            destinationVC?.delegate = self
        }
    }
}

extension AddPostTableViewController: ImageSelectorDelegate {
    func photoPickerSelected(image: UIImage) {
        self.image = image
    }
}

