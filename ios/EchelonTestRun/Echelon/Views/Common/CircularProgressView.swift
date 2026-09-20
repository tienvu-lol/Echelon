import UIKit

class CircularProgressView: UIView {
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let percentageLabel = UILabel()
    private var blurView: UIVisualEffectView?
    
    var progressColor: UIColor = AppTheme.Colors.green {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor: UIColor = AppTheme.Colors.green.withAlphaComponent(0.2) {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var percentage: Int = 0 {
        didSet {
            percentageLabel.text = "\(percentage)%"
            setProgress(CGFloat(percentage) / 100.0)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.cornerRadius = AppTheme.Radii.r22
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        layer.masksToBounds = true
        
        // Apple Liquid Glass background
        let blur = UIVisualEffectView(effect: AppTheme.Effects.makeGlassEffect(style: .systemUltraThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.isUserInteractionEnabled = false
        blur.layer.cornerRadius = AppTheme.Radii.r22
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        insertSubview(blur, at: 0)
        self.blurView = blur
        
        let tint = UIView()
        tint.translatesAutoresizingMaskIntoConstraints = false
        tint.backgroundColor = UIColor(white: 0.08, alpha: 0.35)
        blur.contentView.addSubview(tint)
        
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            tint.topAnchor.constraint(equalTo: blur.contentView.topAnchor),
            tint.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor),
            tint.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor)
        ])
        
        // Track layer
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = 3.5
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)
        
        // Progress layer
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 3.5
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        // Center label: Typography · Label 11 px (bold)
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.textAlignment = .center
        percentageLabel.font = AppTheme.Typography.labelBold
        percentageLabel.textColor = AppTheme.Colors.textPrimary
        addSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            percentageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let radiusCorner = bounds.width / 2
        layer.cornerRadius = radiusCorner
        blurView?.layer.cornerRadius = radiusCorner
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - 6) / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool = false) {
        let clamped = max(0.0, min(1.0, progress))
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clamped
            animation.duration = 0.4
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.strokeEnd = clamped
            progressLayer.add(animation, forKey: "progressAnim")
        } else {
            progressLayer.strokeEnd = clamped
        }
    }
}
