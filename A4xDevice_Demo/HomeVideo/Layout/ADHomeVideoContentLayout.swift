//
//  ADHomeVideoContentLayout.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/12.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit

enum ADVideoRowType {
    case `default`
    case `runing`
}

struct ADVideoStyle {
    var count : Int
    var videoRatio : Float //width height ratio
    var inset : UIEdgeInsets
    var lineSpacing : Float
    var itemSpacing : Float
    var barHeight : Float
    var isSmple : Bool = false

    static func `default` ()-> ADVideoStyle {
        var style = ADVideoStyle(count: 1, videoRatio: 1.8, inset: UIEdgeInsets(top: 2, left: 0, bottom: 16, right: 0), lineSpacing: 16, itemSpacing: 16, barHeight: 50)
        style.isSmple = false
        return style
    }
    
    static func split ()-> ADVideoStyle {
        var style =  ADVideoStyle(count: 2, videoRatio: 1.8, inset: UIEdgeInsets(top: 2, left: 16, bottom: 16, right: 16), lineSpacing: 16 , itemSpacing: 16, barHeight: 30)
        style.isSmple = true
        return style
    }
}

protocol ADHomeVideoContentProtocol : class{
    func getDefaultCellType(rowIndex : Int) -> ADVideoCellType
    func getCellHeight(forRow row : Int , itemWidth : CGFloat) -> CGFloat
}


enum ADVideoCellType : Int {
    static let splitCount           : Int       = 2
    static let splitSpace           : CGFloat   = 1.auto()
    static let splitVerSpace        : CGFloat   = 5.auto()
    static let defaultHorSpace      : CGFloat   = 0.auto()
    static let defaultVerSpace      : CGFloat   = 10.auto()

    case `default`
    case split
    case options_more
    case locations
    case locations_edit
    case playControl
    
}

class ADHomeVideoCollectLayout: UICollectionViewFlowLayout {
    
    var cellAttriArray : [UICollectionViewLayoutAttributes]? = Array()
    var contentHeiht : Float = 0
    weak var mProtocol : ADHomeVideoContentProtocol?
    

    init(delegate dge : ADHomeVideoContentProtocol){
        self.mProtocol = dge
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        debugPrint("-----------> ADHomeVideoCollectLayout prepare")
        cellAttriArray?.removeAll()
        
        let isSplit         : Bool      = (self.mProtocol?.getDefaultCellType(rowIndex: 0) ?? .default) == .split
        let lineCount       : Int       = isSplit ? ADVideoCellType.splitCount : 1
        let rowCount        : Int       = collectionView?.numberOfItems(inSection: 0) ?? 1
        let edgeSpace       : CGFloat   = isSplit ? ADVideoCellType.splitSpace : ADVideoCellType.defaultHorSpace
        let verticalSpace   : CGFloat   = isSplit ? ADVideoCellType.splitVerSpace : ADVideoCellType.defaultVerSpace
        let subViewWidth    : CGFloat   = (self.collectionView?.frame.width ?? UIApplication.shared.keyWindow?.width) ?? 375
        let itemWidth       : CGFloat   = (self.collectionView!.frame.width - edgeSpace * 3 ) / CGFloat(lineCount)

        var xValue : CGFloat = edgeSpace
        var yValue : CGFloat = 0
        var itemHeight : CGFloat = 0
        
        for index in 0 ..< rowCount {
            let indexPath = IndexPath(row: index, section: 0)
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            if let cellHeight = self.mProtocol?.getCellHeight(forRow: index, itemWidth: itemWidth) {
                itemHeight = cellHeight
            }

            let frame = CGRect(x: CGFloat(xValue), y: CGFloat(yValue), width: CGFloat(itemWidth), height: itemHeight)
            attr.frame = frame
            xValue += itemWidth + edgeSpace

            if (xValue + itemWidth) > subViewWidth {
                xValue = edgeSpace
                yValue += (itemHeight + verticalSpace)
            }
            cellAttriArray?.append(attr)

            contentHeiht = frame.maxY.toFloat
        }
        
        contentHeiht += Float(50)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: self.collectionView?.width ?? 0, height: CGFloat(self.contentHeiht))
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        debugPrint("-----------> ADHomeVideoCollectLayout layoutAttributesForElements")

        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        cellAttriArray?.enumerated().forEach({ (index ,element) in
            if (rect.intersects(element.frame)){
                layoutAttributes.append(element)
            }
        })
        
        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        debugPrint("-----------> ADHomeVideoCollectLayout layoutAttributesForItem1")
        return cellAttriArray?[indexPath.row]
    }
}


//class ADHomeVideoContentLayout: UICollectionViewFlowLayout {
//
//    var cellAttriArray : [UICollectionViewLayoutAttributes]? = Array()
//    var contentHeiht : Float = 0
//    weak var mProtocol : ADHomeVideoContentProtocol?
//    var videoStyle : ADVideoStyle
//
//
//    init(style : ADVideoStyle = ADVideoStyle.default(), delegate dge : ADHomeVideoContentProtocol){
//        self.mProtocol = dge
//        self.videoStyle = style
//        super.init()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func prepare() {
//        super.prepare()
//        A4xLog("ADHomeVideoContentLayout prepare")
//        cellAttriArray?.removeAll()
//
//        let lineCount = videoStyle.count
//        guard lineCount > 0 else {
//            return
//        }
//
//        guard videoStyle.videoRatio > 0 else {
//            return
//        }
//
//        let rowCount = collectionView?.numberOfItems(inSection: 0)
//
//        let viewWidth = self.collectionView!.frame.width - videoStyle.inset.left - videoStyle.inset.right
//        let itemTotalWidth = viewWidth / lineCount.toCGFloat
//        var itemWidth = itemTotalWidth
//        if lineCount > 1 {
//             itemWidth = (viewWidth - (lineCount.toCGFloat - 1) * CGFloat(videoStyle.itemSpacing) )/lineCount.toCGFloat
//        }
//        let itemHeight = itemWidth / CGFloat(videoStyle.videoRatio)
//
//        var xValue : CGFloat = videoStyle.inset.left
//        var yValue : CGFloat = videoStyle.inset.top
//
//        for index in 0 ..< rowCount! {
//            let indexPath = IndexPath(row: index, section: 0)
//            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
//
//            if (xValue + itemWidth) > (viewWidth + videoStyle.inset.right + 1) {
//                xValue = videoStyle.inset.left
//                yValue += itemHeight + CGFloat(videoStyle.barHeight) + CGFloat(videoStyle.lineSpacing)
//            }
//            var height = itemHeight;
//            height += CGFloat(videoStyle.barHeight)
//
//            var contentHeight : CGFloat = 0
//            if lineCount == 1 {
////                if self.mProtocol?.getDefaultCellType(rowIndex: index)  == .runing {
////                    contentHeight = 245.auto()
////                }
//                contentHeight = 245.auto()
//
//            }
//
//            let frame = CGRect(x: CGFloat(xValue), y: CGFloat(yValue), width: CGFloat(itemWidth), height: height + contentHeight)
//            attr.frame = frame
//            xValue += itemWidth + CGFloat(videoStyle.itemSpacing)
//            yValue += contentHeight
//            contentHeiht = frame.maxY.toFloat
//            cellAttriArray?.append(attr)
//        }
//        contentHeiht += Float(videoStyle.inset.bottom)
//    }
//
//    override var collectionViewContentSize: CGSize {
//        return CGSize(width: self.collectionView?.width ?? 0, height: CGFloat(self.contentHeiht))
//    }
//
//    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
//        A4xLog("ADHomeVideoContentLayout layoutAttributesForElements")
//
//        var layoutAttributes = [UICollectionViewLayoutAttributes]()
//
//        cellAttriArray?.enumerated().forEach({ (index ,element) in
//            if (rect.intersects(element.frame)){
//                layoutAttributes.append(element)
//            }
//        })
//
//        return layoutAttributes
//    }
//
//    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        A4xLog("ADHomeVideoContentLayout layoutAttributesForItem2")
//
//        return cellAttriArray?[indexPath.row]
//    }
//}
