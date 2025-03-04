import Cocoa

class AboutWindowController: NSWindowController {
    static let shared = AboutWindowController()
    
    private init() {
        super.init(window: nil)
        self.loadWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = NSLocalizedString("About Clipboard Helper", comment: "")
        window.level = .floating
        window.center()
        
        let contentView = AboutContentView()
        window.contentView = contentView
        
        self.window = window
    }
}

private class AboutContentView: NSView {
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 400, height: 260)) // Увеличили высоту
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.spacing = 8
        
        // Иконка приложения
        let icon = NSImage(named: "AppIcon")?.resize(to: NSSize(width: 64, height: 64))
        let iconView = NSImageView(image: icon ?? NSImage())
        
        // Строка с названием и версией
        let titleVersionStack = NSStackView()
        titleVersionStack.orientation = .horizontal
        titleVersionStack.alignment = .lastBaseline
        titleVersionStack.spacing = 8
        
        // Название приложения
        let titleLabel = NSTextField(labelWithString: "Clipboard Helper")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        
        // Версия
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let versionLabel = NSTextField(labelWithString: "\(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        
        titleVersionStack.addArrangedSubview(titleLabel)
        titleVersionStack.addArrangedSubview(versionLabel)
        

        // Описание приложения
        let descriptionLabel = NSTextField(labelWithString: NSLocalizedString("Description", comment: ""))
        descriptionLabel.font = NSFont.systemFont(ofSize: 12)
    
        
        // Автор
        let authorLabel = NSTextField(labelWithString: NSLocalizedString("Author_Text", comment: ""))
        authorLabel.font = NSFont.systemFont(ofSize: 12)
        
        // Ссылка
        let link = HyperlinkTextField()
        link.setLink(
            NSLocalizedString("Source_Code", comment: ""),
            url: URL(string: "https://github.com/yourusername/clipboard-helper")!
        )
        
        // Настройка layout
        mainStack.addArrangedSubview(iconView)
        mainStack.setCustomSpacing(16, after: iconView)
        mainStack.addArrangedSubview(titleVersionStack)
        mainStack.setCustomSpacing(8, after: titleVersionStack)
        mainStack.addArrangedSubview(descriptionLabel)
        mainStack.setCustomSpacing(32, after: descriptionLabel)
        mainStack.addArrangedSubview(authorLabel)
        mainStack.setCustomSpacing(8, after: authorLabel)
        mainStack.addArrangedSubview(link)
        
        // Центрирование содержимого
        let container = NSView()
        container.addSubview(mainStack)
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20)
        ])
        
        // Настройка главного view
        self.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: self.topAnchor, constant: 24),
            container.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -24),
            container.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24)
        ])
    }
}

class HyperlinkTextField: NSTextField {
    private var url: URL?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.alignment = .center
        self.isSelectable = false
        self.isEditable = false
        self.drawsBackground = false
        self.isBordered = false
    }
    
    func setLink(_ text: String, url: URL) {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)
        
        attributedString.addAttributes([
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: centeredParagraphStyle()
        ], range: range)
        
        attributedString.addAttributes([
            .link: url,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: NSColor.systemBlue,
            .cursor: NSCursor.pointingHand
        ], range: range)
        
        self.attributedStringValue = attributedString
        self.url = url
    }
    
    private func centeredParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }
    
    override func mouseDown(with event: NSEvent) {
        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }
    
    override func resetCursorRects() {
        super.resetCursorRects()
        if url != nil {
            self.addCursorRect(self.bounds, cursor: .pointingHand)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Фиксируем положение текста при перерисовке
        self.alignment = .center
    }
}

extension NSImage {
    func resize(to size: NSSize) -> NSImage {
        return NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect)
            return true
        }
    }
}
