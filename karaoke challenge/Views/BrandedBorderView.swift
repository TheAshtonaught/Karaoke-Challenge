import UIKit

final class BrandedBorderView: UIView {
    enum State {
        case idle
        case singing
        case success
        case failure
    }

    private let borderLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 4
        layer.addSublayer(glowLayer)
        layer.addSublayer(borderLayer)

        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.lineWidth = 10
        glowLayer.opacity = 0

        apply(state: .idle, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 6, dy: 6), cornerRadius: 20).cgPath
        borderLayer.path = path
        glowLayer.path = path
    }

    func apply(state: State, animated: Bool = true) {
        glowLayer.removeAllAnimations()

        let colors: (UIColor, UIColor)
        switch state {
        case .idle:
            colors = (UIColor.white.withAlphaComponent(0.7), UIColor.white.withAlphaComponent(0.15))
            glowLayer.opacity = 0
        case .singing:
            colors = (UIColor.systemYellow, UIColor.systemOrange)
            glowLayer.opacity = 0.55
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.25
            pulse.toValue = 0.75
            pulse.duration = 0.6
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            glowLayer.add(pulse, forKey: "pulse")
        case .success:
            colors = (UIColor.systemGreen, UIColor.systemGreen.withAlphaComponent(0.6))
            glowLayer.opacity = 0.45
        case .failure:
            colors = (UIColor.systemRed, UIColor.systemRed.withAlphaComponent(0.6))
            glowLayer.opacity = 0.45
        }

        if animated {
            let colorAnimation = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation.duration = 0.25
            colorAnimation.fromValue = borderLayer.strokeColor
            colorAnimation.toValue = colors.0.cgColor
            borderLayer.add(colorAnimation, forKey: "strokeColor")
        }

        borderLayer.strokeColor = colors.0.cgColor
        glowLayer.strokeColor = colors.1.cgColor
    }
}
