//
// ExcelView.swift
// 仿 Excel 表格，固定顶部栏和左侧标题栏固定，内容部分可以上下左右滑动
//
import UIKit

@objc public protocol ExcelViewDataSource: NSObjectProtocol {
    func numberOfRows() -> Int
    func numberOfColumns() -> Int
    func rowHeightOfTopTitle() -> CGFloat
    func columnWidthOfLeftTitle() -> CGFloat
    func rowHeightAt(row: Int) -> CGFloat
    func columnWidthAt(column: Int) -> CGFloat
    func rowNameAt(row: Int) -> String
    func columnNameAt(column: Int) -> String
    func rowDataAt(row: Int) -> [String]
}

@objc public protocol ExcelViewDelegate: NSObjectProtocol {
    @objc optional func excelView(_ excelView: ExcelView, didTapGridWith content: String)
    @objc optional func excelView(_ excelView: ExcelView, didTapColumnHeaderWith name: String)
}

open class ExcelView: UIView {
    open weak var dataSource: ExcelViewDataSource? {
        didSet {
            reloadData()
        }
    }
    open weak var delegate: ExcelViewDelegate?
    
    lazy var svTopTitles: UIScrollView = UIScrollView(frame: CGRect.zero)
    lazy var tvLeftTitles: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    lazy var svContent: UIScrollView = UIScrollView(frame: CGRect.zero)
    lazy var tvContent: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    var columnWidths = [CGFloat]()
    var columnNameLabels = [UILabel]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    func setupViews() {
        // 顶部标题栏
        svTopTitles.scrollsToTop = false
        svTopTitles.showsHorizontalScrollIndicator = false
        svTopTitles.bounces = false
        svTopTitles.delegate = self
        addSubview(svTopTitles)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTopHeader(_:)))
        svTopTitles.addGestureRecognizer(tap)

        // 左侧标题栏
        tvLeftTitles.backgroundColor = UIColor.clear
        tvLeftTitles.scrollsToTop = false
        tvLeftTitles.separatorStyle = .none
        tvLeftTitles.showsVerticalScrollIndicator = false
        tvLeftTitles.bounces = false
        tvLeftTitles.register(LeftTitleCell.self, forCellReuseIdentifier: "LeftTitleCell")
        tvLeftTitles.dataSource = self
        tvLeftTitles.delegate = self
        addSubview(tvLeftTitles)
        
        // 中间内容
        svContent.scrollsToTop = false
        svContent.bounces = false
        svContent.delegate = self
        addSubview(svContent)
        
        tvContent.backgroundColor = UIColor.clear
        tvContent.scrollsToTop = true
        tvContent.separatorStyle = .none
        tvContent.bounces = false
        tvContent.dataSource = self
        tvContent.delegate = self
        svContent.addSubview(tvContent)
        
        if #available(iOS 11.0, *) {
            svTopTitles.contentInsetAdjustmentBehavior = .never
            svContent.contentInsetAdjustmentBehavior = .never
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let dataSource = dataSource else {
            return
        }
        var columnTotalWidth: CGFloat = 0
        for columnWidth in columnWidths {
            columnTotalWidth += columnWidth
        }
        let leftHeaderWidth = dataSource.columnWidthOfLeftTitle()
        let topHeaderHeight = dataSource.rowHeightOfTopTitle()
        svTopTitles.frame = CGRect(x: leftHeaderWidth, y: 0, width: bounds.size.width - leftHeaderWidth, height: topHeaderHeight)
        svTopTitles.contentSize = CGSize(width: columnTotalWidth, height: topHeaderHeight)
        
        tvLeftTitles.frame = CGRect(x: 0, y: topHeaderHeight, width: leftHeaderWidth, height: bounds.size.height - topHeaderHeight)
        
        svContent.frame = CGRect(x: leftHeaderWidth, y: topHeaderHeight, width: svTopTitles.bounds.size.width, height: tvLeftTitles.bounds.size.height)
        svContent.contentSize = CGSize(width: columnTotalWidth, height: svContent.bounds.size.height)
        tvContent.frame = CGRect(x: 0, y: 0, width: columnTotalWidth, height: svContent.bounds.size.height)
    }
    
    func reloadData() {
        reloadTopTitles()
        tvLeftTitles.reloadData()
        tvContent.reloadData()
    }
    
    func reloadTopTitles() {
        guard let dataSource = dataSource else {
            return
        }
        svTopTitles.subviews.forEach { $0.removeFromSuperview() }
        let numberOfColumns = dataSource.numberOfColumns()
        guard numberOfColumns > 0 else {
            return
        }
        let headerHeight = dataSource.rowHeightOfTopTitle()
        columnWidths.removeAll()
        columnNameLabels.removeAll()
        var x: CGFloat = 0
        for index in 0..<numberOfColumns {
            let columnWidth = dataSource.columnWidthAt(column: index)
            columnWidths.append(columnWidth)
            let lbTopTitle = UILabel(frame: CGRect(x: x, y: 0, width: columnWidth, height: headerHeight))
            x += columnWidth
            lbTopTitle.text = dataSource.columnNameAt(column: index)
            lbTopTitle.textColor = UIColor.white
            lbTopTitle.font = .systemFont(ofSize: 12.screenAdapt())
            lbTopTitle.textAlignment = .center
            svTopTitles.addSubview(lbTopTitle)
            columnNameLabels.append(lbTopTitle)
        }
    }
    
    @objc func didTapTopHeader(_ tap: UITapGestureRecognizer) {
        guard let dataSource = dataSource else {
            return
        }
        let point = tap.location(in: svTopTitles)
        for (index, label) in columnNameLabels.enumerated() {
            if (label.frame.contains(point)) {
                delegate?.excelView?(self, didTapColumnHeaderWith: dataSource.columnNameAt(column: index))
                break
            }
        }
    }
}

extension ExcelView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let dataSource = dataSource else {
            return 0
        }
        if (tableView == tvLeftTitles) {
            return dataSource.numberOfRows()
        } else if (tableView == tvContent) {
            return dataSource.numberOfRows()
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let dataSource = dataSource else {
            return UITableViewCell(style: .default, reuseIdentifier: "default")
        }
        var cell: UITableViewCell?
        if (tableView == tvLeftTitles) {
            cell = tableView.dequeueReusableCell(withIdentifier: "LeftTitleCell", for: indexPath)
            let leftTitleCell = cell as! LeftTitleCell
            let rowName = dataSource.rowNameAt(row: indexPath.row)
            leftTitleCell.titleLabel.text = rowName
        } else if (tableView == tvContent) {
            cell = tableView.dequeueReusableCell(withIdentifier: ContentCell.cellIdentifier(columnCount: dataSource.numberOfColumns()))
            if (cell == nil) {
               cell = ContentCell(columnCount: dataSource.numberOfColumns())
            }
            let contentCell = cell as! ContentCell
            contentCell.reloadData(rowDatas: dataSource.rowDataAt(row: indexPath.row), columnWidths: columnWidths)
            contentCell.didTapClosure = {[weak self] (itemContent) in
                self?.delegate?.excelView?(self!, didTapGridWith: itemContent)
            }
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "default")
        }
        cell?.selectionStyle = .none
        // 背景色透明
        cell?.backgroundColor = UIColor.clear
        return cell!
    }
}

extension ExcelView: UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == tvContent) {
            tvLeftTitles.contentOffset = scrollView.contentOffset
        } else if (scrollView == tvLeftTitles) {
            tvContent.contentOffset = scrollView.contentOffset
        } else if (scrollView == svContent) {
            svTopTitles.contentOffset = scrollView.contentOffset
        } else if (scrollView == svTopTitles) {
            svContent.contentOffset = scrollView.contentOffset
        }
    }
}

class LeftTitleCell: UITableViewCell {
    let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.font = .systemFont(ofSize: 12.screenAdapt())
        titleLabel.textColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = contentView.bounds
    }
}

class ContentCell: UITableViewCell {
    var didTapClosure: ((String)->())?
    var itemLabels = [UILabel]()
    private var rowDatas: [String]?
    
    deinit {
        didTapClosure = nil
    }
    
    init(columnCount: Int) {
        super.init(style: .default, reuseIdentifier: ContentCell.cellIdentifier(columnCount: columnCount))
        for _ in 0..<columnCount {
            let lbContent = UILabel()
            lbContent.textColor = UIColor.white
            lbContent.font = .systemFont(ofSize: 13)
            lbContent.textAlignment = .center
            contentView.addSubview(lbContent)
            itemLabels.append(lbContent)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        contentView.addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func cellIdentifier(columnCount: Int) -> String {
        return "contentCell-\(columnCount)"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        itemLabels.forEach { (label) in
            label.frame.size.height = self.contentView.bounds.size.height
        }
    }
    
    @objc func didTap(_ tap: UITapGestureRecognizer) {
        guard rowDatas != nil else {
            return
        }
        let point = tap.location(in: contentView)
        for (index, label) in itemLabels.enumerated() {
            if label.frame.contains(point) {
                didTapClosure?(rowDatas![index])
                break
            }
        }
    }
    
    func reloadData(rowDatas: [String], columnWidths: [CGFloat]) {
        self.rowDatas = rowDatas
        var x: CGFloat = 0
        for index in 0..<itemLabels.count {
            let lbContent = itemLabels[index]
            let columnWidth = columnWidths[index]
            lbContent.frame = CGRect(x: x, y: 0, width: columnWidth, height: 0)
            x += columnWidth
            lbContent.text = rowDatas[index]
        }
    }
}

