import UIKit

final class MainMenuViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Karaoke Challenge"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Fill in the missing lyric."
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let pickSongButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Pick a Song"
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Home"

        [titleLabel, subtitleLabel, pickSongButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        pickSongButton.addTarget(self, action: #selector(pickSongTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            pickSongButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickSongButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            pickSongButton.widthAnchor.constraint(equalToConstant: 220),
            pickSongButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func pickSongTapped() {
        let selectionVC = SongSelectionViewController()
        navigationController?.pushViewController(selectionVC, animated: true)
    }
}
