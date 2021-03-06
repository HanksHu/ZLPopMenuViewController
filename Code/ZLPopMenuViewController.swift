//
//  ZLPopMenuViewController.swift
//  ZLPopMenu
//
//  Created by 胡智林 on 2018/11/26.
//  Copyright © 2018 胡智林. All rights reserved.
//

import UIKit

public class ZLPopMenuViewController: UIViewController {
   
    @objc public var menuData = [ZLPopMenuModel]() {
        didSet {
            if menuData == oldValue {
                return
            }
            configContentView()
        }
    }
     // MARK: - 一些回调通知
    ///点击item的回调
    @objc public var didClickItems: ((Int, ZLPopMenuModel) -> Void)?
    ///
    @objc public var didTapBackgroundView: (() -> Void)?
    ///
    @objc public var didDismiss: (() -> Void)?
    ///
    @objc public var willDismiss: (() -> Void)?
    
    private lazy var tableView: UITableView = {
        let table = UITableView.init()
        table.frame = .init(x: 100, y: 200, width: 200, height: 400)
        table.delegate = self
        table.dataSource = self
        table.register(ZLPopMenuTableViewCell.self, forCellReuseIdentifier: "ZLPopMenuTableViewCell")
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        return table
    }()
    ///三角箭头
    private let triangleView = ZlTriangleView()
    
    ///大的背景view
    public lazy var backgroundView: UIView = {
        let bkView = UIView()
        bkView.frame = view.frame
        bkView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        bkView.translatesAutoresizingMaskIntoConstraints = false
        bkView.addGestureRecognizer(tapGestureForDismissal)
        bkView.isUserInteractionEnabled = true
        return bkView
    }()
    fileprivate lazy var tapGestureForDismissal: UITapGestureRecognizer = {
        let tapper = UITapGestureRecognizer(target: self, action: #selector(backgroundViewDidTap(_:)))
        tapper.cancelsTouchesInView = false
        tapper.delaysTouchesEnded = false
        
        return tapper
    }()
    //放箭头和tabelview的
    public lazy var contentView: UIView = {
        let cview = UIView()
        cview.backgroundColor = .clear
        cview.layer.cornerRadius = 5
        cview.layer.masksToBounds = true
        return cview
    }()
    private var menuStyle = ZLPopMenuStyle.white
    private var menuCf = ZLPopMenuConfig.default
    private var absoluteSourceFrame = CGRect.zero
    
    deinit {
        print(type(of: self), #function)
    }
    
    private init() {
        super.init(nibName: nil, bundle: nil)
    }
    // MARK: - public method
    
    /// 初始化
    ///
    /// - Parameters:
    ///   - sourceView: sourceView
    ///   - menuData: 数据
    ///   - popMenuConfig: 配置
    @objc public convenience init(sourceView: AnyObject,
                            menuData: [ZLPopMenuModel] = [],
                            menuStyle: ZLPopMenuStyle = .white,
                            popMenuConfig: ZLPopMenuConfig = .default) {
        self.init()
        self.menuStyle = menuStyle
        self.menuData = menuData
        menuCf = popMenuConfig
        modalPresentationStyle = .overFullScreen
        transitioningDelegate = self
        modalPresentationCapturesStatusBarAppearance = true
        
        if let sourceBarButtonItem = sourceView as? UIBarButtonItem {
            if let buttonView = sourceBarButtonItem.value(forKey: "view") as? UIView {
                absoluteSourceFrame = buttonView.convert(buttonView.bounds, to: nil)
            }
        }
        if let sourceView = sourceView as? UIView {
            absoluteSourceFrame = sourceView.convert(sourceView.bounds, to: nil)
        }
        
    }
    
    /// 新增一个
    ///
    /// - Parameter model: 新数据
    @objc public func appendModel(new model: ZLPopMenuModel) {
        menuData.append(model)
        configContentView()
    }
    
    /// 更新数据
    ///
    /// - Parameters:
    ///   - model: 新的数据
    ///   - index: 索引
    @objc public func updateModel(new model: ZLPopMenuModel, _ index: Int) {
        if index >= menuData.count {
            return
        }
        menuData[index] = model
        tableView.reloadData()
    }
//    public func deletModel(_ model: ZLPopMenuModel) {
//
//
//    }
    
    // MARK: - public method
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func viewDidLoad() {
        
        view.backgroundColor = UIColor.clear
        view.addSubview(backgroundView)
        view.addSubview(contentView)
        contentView.addSubview(tableView)
        contentView.addSubview(triangleView)
        configContentView()
    }
    ///每次更新数据和远点都要重新计算
    private func configContentView() {
        switch menuStyle {
        case .white:
            triangleView.backgroundColor = .white
        case .black:
            triangleView.backgroundColor = .black
        }
        
        
        let tableViewH = CGFloat(min(menuCf.defaultMaxValue, menuData.count)) * menuCf.cellH
        
        tableView.isScrollEnabled = menuData.count > menuCf.defaultMaxValue
        
        let sourceCenterX = absoluteSourceFrame.origin.x + absoluteSourceFrame.width/2.0
        
        
        var triangleViewX = sourceCenterX - menuCf.triangleW/2.0
        
        ///如果超过右边
        if sourceCenterX + menuCf.triangleW/2.0 + menuCf.margin > view.frame.width {
            triangleViewX = view.frame.width - (menuCf.triangleW + menuCf.margin + 3)
        }
        //如果超过左边
        if sourceCenterX - menuCf.triangleW/2.0 - menuCf.margin < 0 {
            triangleViewX =  menuCf.margin + 3
        }
        
        var tableViewFrameX = sourceCenterX - menuCf.tableViewW/2.0
        ///如果超过右边
        if sourceCenterX + menuCf.tableViewW/2.0 + menuCf.margin > view.frame.width {
            tableViewFrameX = view.frame.width - (menuCf.tableViewW + menuCf.margin)
        }
        //如果超过左边
        if sourceCenterX - menuCf.tableViewW/2.0 - menuCf.margin < 0 {
            tableViewFrameX = menuCf.margin
        }
        contentView.frame = .init(x: tableViewFrameX, y: absoluteSourceFrame.maxY, width: menuCf.tableViewW, height: tableViewH + menuCf.triangleH)
        
        tableView.frame = .init(x: 0, y: menuCf.triangleH, width: menuCf.tableViewW, height: tableViewH)
        triangleView.frame = .init(x: triangleViewX - contentView.frame.origin.x , y: 0, width: menuCf.triangleW, height: menuCf.triangleH)
        tableView.reloadData()
        
    }
    
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        dismiss(animated: true, completion: nil)
//    }
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        
        return .default
    }

    
    
    @objc fileprivate func backgroundViewDidTap(_ gesture: UITapGestureRecognizer) {
        //        guard gesture.isEqual(tapGestureForDismissal), !touchedInsideContent(location: gesture.location(in: view)) else { return }
        didTapBackgroundView?()
        willDismiss?()
        dismiss(animated: true) {[unowned self]() in
            self.didDismiss?()
        }
    }
}
extension ZLPopMenuViewController: UIViewControllerTransitioningDelegate {
    //     Custom presentation animation.
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZLPopMenuPresentAnimationController(sourceFrame: absoluteSourceFrame)
    }
    
    /// Custom dismissal animation.
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZLPopMenuDismissAnimationController(sourceFrame: absoluteSourceFrame)
    }
}


extension ZLPopMenuViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didClickItems?(indexPath.row, menuData[indexPath.row])
        willDismiss?()
        dismiss(animated: true) {[unowned self]() in
            self.didDismiss?()
        }
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return menuData.count
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return menuCf.cellH
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZLPopMenuTableViewCell", for: indexPath) as! ZLPopMenuTableViewCell
        
        cell.cellModel = menuData[indexPath.row]
        switch menuStyle {
        case .black:
            cell.backgroundColor = .black
            cell.textLabel?.textColor = .white
//            cell.selectionStyle = .gray
        case .white:
            cell.backgroundColor = .white
            cell.textLabel?.textColor = .black
//            cell.selectionStyle = .default
        }
        return cell
    }
    
}
