//
//  ImgViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2024/2/19.
//  共享图片时，展示单张图片的界面
//

import UIKit
import common
import SnapKit

class ImgViewController: UIViewController {
    private let img: UIImage
    private var imageCapturerSource: UIImage?
    private let ivImg = {
        let imageView = UIImageView()
        return imageView
    }()
    
    init(img: UIImage) {
        self.img = img
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .black
        ivImg.contentMode = .scaleAspectFit
        ivImg.image = img
        view.addSubview(ivImg)
        ivImg.snp.makeConstraints { make in
            if (ScreenUtil.isPortrait()) {
                // 宽小于高时，以宽为基准进行缩放
                make.width.equalToSuperview()
                make.height.equalTo(ivImg.snp.width).multipliedBy(16.0/9.0)
            } else {
                // 宽大于高时，以高为基准进行缩放
                make.height.equalToSuperview()
                make.width.equalTo(ivImg.snp.height).multipliedBy(16.0/9.0)
            }
            make.center.equalToSuperview()
        }
    }
    
    func getImageCapturerSource() -> UIImage? {
        return imageCapturerSource
    }
    
    func setImageCapturerSource(_ uiImage: UIImage){
        imageCapturerSource = uiImage
    }
}
