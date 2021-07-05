//
//  UIImage+Helper.swift
//  SwiftTemplet
//
//  Created by dev on 2018/12/11.
//  Copyright © 2018年 BN. All rights reserved.
//

import UIKit

//MARK - UIImage
public extension UIImage {

    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func isWhole() -> Bool{
        guard let cgImage = self.cgImage else {
            return true
        }
        
        let width = Int(self.size.width)
        let height = Int(self.size.height)

        guard let pixelData = cgImage.dataProvider?.data else {
            return true
        }
        let data : UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        var red : UInt8  = 1
        var green : UInt8  = 1
        var blue : UInt8  = 1
        var alpha : UInt8  = 1

        for x in 0..<width {
            for y in 0..<height {
                let point = CGPoint(x: x, y: y)
                let pixelInfo: Int = ((width * Int(point.y)) + Int(point.x)) * 4
                let r = data[pixelInfo]
                let g = data[pixelInfo + 1]
                let b = data[pixelInfo + 2]
                let a = data[pixelInfo + 3]
                if x == 0 && y == 0 {
                    red = r
                    green = g
                    blue = b
                    alpha = a
                    break
                }
                
              
                if red != r || green != g || blue != b || alpha != a {
                    return false
                }
            }
        }
        
        return true
    }
    
    func croppedImage(bound : CGRect) -> UIImage {
        let scaledBounds = CGRect(x:bound.origin.x * self.scale, y:bound.origin.y * self.scale, width:bound.size.width * self.scale, height:bound.size.height * self.scale)
        let imageRef = cgImage?.cropping(to:scaledBounds)
        let croppedImage = UIImage(cgImage: imageRef!, scale: self.scale, orientation: .up)
        
        return croppedImage
    }
    
    static func generateQRImage(QRCodeString: String, logo: UIImage?, size: CGSize = CGSize(width: 50, height: 50)) -> UIImage? {
        guard let data = QRCodeString.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }
        let imageFilter = CIFilter(name: "CIQRCodeGenerator")
        imageFilter?.setValue(data, forKey: "inputMessage")
        imageFilter?.setValue("H", forKey: "inputCorrectionLevel")
        let ciImage = imageFilter?.outputImage
        
        // 创建颜色滤镜
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setDefaults()
        colorFilter?.setValue(ciImage, forKey: "inputImage")
        colorFilter?.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")
        colorFilter?.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")
        
        // 返回二维码图片
        let qrImage = UIImage(ciImage: (colorFilter?.outputImage)!)
        let imageRect = size.width > size.height ?
            CGRect(x: (size.width - size.height) / 2, y: 0, width: size.height, height: size.height) :
            CGRect(x: 0, y: (size.height - size.width) / 2, width: size.width, height: size.width)
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        qrImage.draw(in: imageRect)
        if logo != nil {
            let logoSize = size.width > size.height ?
                CGSize(width: size.height * 0.25, height: size.height * 0.25) :
                CGSize(width: size.width * 0.25, height: size.width * 0.25)
            logo?.draw(in: CGRect(x: (imageRect.size.width - logoSize.width) / 2, y: (imageRect.size.height - logoSize.height) / 2, width: logoSize.width, height: logoSize.height))
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
  
    func roundImage(byRoundingCorners: UIRectCorner = UIRectCorner.allCorners, cornerRadi: CGFloat) -> UIImage? {
        return roundImage(byRoundingCorners: byRoundingCorners, cornerRadii: CGSize(width: cornerRadi, height: cornerRadi))
    }
    
    func roundImage(byRoundingCorners: UIRectCorner = UIRectCorner.allCorners, cornerRadii: CGSize) -> UIImage? {
        
        let imageRect = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer {
            UIGraphicsEndImageContext()
        }
        let context = UIGraphicsGetCurrentContext()
        guard context != nil else {
            return nil
        }
        context?.setShouldAntialias(true)
        let bezierPath = UIBezierPath(roundedRect: imageRect,
                                      byRoundingCorners: byRoundingCorners,
                                      cornerRadii: cornerRadii)
        bezierPath.close()
        bezierPath.addClip()
        self.draw(in: imageRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    
    func tinColor(color : UIColor) -> UIImage{
        
        UIGraphicsBeginImageContext(self.size)
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
    
    // 图片大小设置
    func compression(toSize : CGSize) -> UIImage? {
        //实现等比例缩放
        let hfactor =  toSize.width / self.size.width
        let vfactor =  toSize.height / self.size.height
        let factor = fmin(hfactor, vfactor);
        //画布大小
        let imageWidth : CGFloat = self.size.width
        let imageHeight : CGFloat = self.size.height
        let newWith: CGFloat = imageWidth * factor
        let newHeigth: CGFloat = imageHeight * factor
        let newSize = CGSize(width: newWith, height: newHeigth)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: newWith, height: newHeigth))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func compression(scale : CGFloat) -> UIImage? {
        //画布大小
        let newWith: CGFloat = self.size.width * scale
        let newHeigth: CGFloat = self.size.height * scale
        let newSize = CGSize(width: newWith, height: newHeigth)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: newWith, height: newHeigth))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /*!
     *  @brief 使图片压缩后刚好小于指定大小
     *
     *  @param image 当前要压缩的图 maxLength 压缩后的大小
     *
     *  @return 图片对象
     */
    // 图片压缩
    func compressImageMid(_ maxLength: NSInteger, _ cyles: Int = 6) -> Data {
        var compression: CGFloat = 1
        var data = self.jpegData(compressionQuality: compression)!
        if data.count < maxLength {
            return data
        }
        //原图大小超过范围，先进行“压处理”，这里 压缩比 采用二分法进行处理，6次二分后的最小压缩比是0.015625，已经够小了
        var max: CGFloat = 1
        var min: CGFloat = 0
        var bestData: Data = data
        for _ in 0..<cyles {
            compression = (max + min) / 2
            data = self.jpegData(compressionQuality: compression)!
            if Double(data.count) < Double(maxLength) * 0.9 {
                min = compression
                bestData = data
            } else if data.count > maxLength {
                max = compression
            } else {
                bestData = data
                break
            }
        }
        return bestData
    }
    
    
    /// 根据尺寸重新生成图片
    ///
    /// - Parameter size: 设置的大小
    /// - Returns: 新图
    func imageWithNewSize(size: CGSize) -> UIImage? {
        if self.size.height > size.height {
            let width = size.height / self.size.height * self.size.width
            let newImgSize = CGSize(width: width, height: size.height)
            UIGraphicsBeginImageContext(newImgSize)
            self.draw(in: CGRect(x: 0, y: 0, width: newImgSize.width, height: newImgSize.height))
            let theImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let newImg = theImage else { return  nil}
            return newImg
        } else {
            let newImgSize = CGSize(width: size.width, height: size.height)
            UIGraphicsBeginImageContext(newImgSize)
            self.draw(in: CGRect(x: 0, y: 0, width: newImgSize.width, height: newImgSize.height))
            let theImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let newImg = theImage else { return  nil}
            return newImg
        }
    }
}
