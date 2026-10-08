import Purchasely
import SwiftUI
import UIKit

public class CustomScreenViewControllerDelegate: PLYCustomScreenViewControllerDelegate {
    public func viewController(for presentation: PLYPresentation) -> UIViewController? {
        switch presentation.screenId {
        case "byos_flow_custom_first":
            let vc = UIViewController()
            
            let label = UILabel()
            label.text = "Hello UIKit World!\n(byos_flow_custom_first)"
            label.font = .systemFont(ofSize: 36, weight: .semibold)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .white
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let buttons = presentation.connections.map { connection in
                let button = UIButton()
                button.setTitle(" 👉 \(connection.id) 👈 ", for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
                if #available(iOS 14.0, *) {
                    button.addAction(UIAction { _ in
                        presentation.executeConnection(connection)
                    }, for: .touchUpInside)
                } else {
                    // Fallback on earlier versions
                }
                
                button.translatesAutoresizingMaskIntoConstraints = false
                button.layer.cornerRadius = 10
                button.backgroundColor = .systemBlue

                return button
            }
            
            let stackView = UIStackView(arrangedSubviews: buttons)
            stackView.axis = .vertical
            stackView.spacing = 10
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            vc.view.addSubview(label)
            vc.view.addSubview(stackView)
            vc.view.backgroundColor = .green
            
            NSLayoutConstraint.activate(buttons.map { button in
                button.heightAnchor.constraint(equalToConstant: 40)
            })
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
                stackView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
                stackView.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
            
            return vc
        default:
            return nil
        }
    }
}

public class CustomScreenViewDelegate: PLYCustomScreenViewDelegate {

    @ViewBuilder public func view(for presentation: PLYPresentation) -> some View {
        VStack {
            Spacer()
            label(presentationId: presentation.screenId)
            Spacer()
            ForEach(Array(presentation.connections), id: \.id) { connection in
                button(title: connection.id, for: presentation, with: connection)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.red)
    }
}

@available(iOS 15.0, *)
fileprivate func label(presentationId: String) -> some View {
    Label("Hello SwiftUI World!\n(\(presentationId))", systemImage: "globe.europe.africa.fill")
        .font(.headline)
        .foregroundStyle(.white)
}

@available(iOS 15.0, *)
fileprivate func button(title: String, for presentation: PLYPresentation, with connection: PLYConnection) -> some View {
    Button(action: {
        presentation.executeConnection(connection)
    }, label: {
        Text("👉 \(title) 👈")
            .font(.largeTitle)
            .padding()
            .background(.white)
    })
    .cornerRadius(10)
}
