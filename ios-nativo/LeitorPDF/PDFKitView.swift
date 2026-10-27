import SwiftUI
import PDFKit

/// Mostra o PDF, destaca a frase que está sendo lida e informa a página visível.
struct PDFKitView: UIViewRepresentable {
    let documento: PDFDocument
    let destaque: PDFSelection?
    @Binding var paginaVisivel: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = documento
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        NotificationCenter.default.addObserver(
            context.coordinator, selector: #selector(Coordinator.paginaMudou(_:)),
            name: .PDFViewPageChanged, object: view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        guard let destaque else {
            view.highlightedSelections = nil
            return
        }
        destaque.color = UIColor.systemYellow.withAlphaComponent(0.45)
        view.highlightedSelections = [destaque]

        // Acompanha a leitura só quando a frase sai da página que está na tela.
        if let pagina = destaque.pages.first, pagina != view.currentPage {
            view.go(to: destaque)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        let pai: PDFKitView
        init(_ pai: PDFKitView) { self.pai = pai }

        @MainActor @objc func paginaMudou(_ aviso: Notification) {
            guard let view = aviso.object as? PDFView,
                  let pagina = view.currentPage,
                  let indice = view.document?.index(for: pagina) else { return }
            pai.paginaVisivel = indice
        }
    }
}
