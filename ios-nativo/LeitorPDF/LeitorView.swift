import SwiftUI
import PDFKit
import AVFoundation

struct LeitorView: View {
    let url: URL

    @StateObject private var leitor = LeitorDeVoz()
    @State private var documento: PDFDocument?
    @State private var paginaVisivel = 0
    @State private var carregando = true

    var body: some View {
        VStack(spacing: 0) {
            if let documento {
                PDFKitView(documento: documento, destaque: destaqueAtual, paginaVisivel: $paginaVisivel)
            } else {
                Spacer()
                ProgressView("Abrindo PDF…")
                Spacer()
            }

            if !carregando && leitor.trechos.isEmpty {
                Text("Este PDF não tem texto selecionável (parece uma digitalização). A leitura de PDFs escaneados com OCR fica para a próxima versão.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
            }

            controles
        }
        .navigationTitle(url.deletingPathExtension().lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { menuDeVozes }
        .task { await abrir() }
        .onDisappear { leitor.pausar() }
    }

    private var destaqueAtual: PDFSelection? {
        guard let trecho = leitor.trechoAtual,
              let pagina = documento?.page(at: trecho.pagina) else { return nil }
        return pagina.selection(for: trecho.intervalo)
    }

    private func abrir() async {
        documento = PDFDocument(url: url)
        leitor.aoMudarPosicao = { [url] indice in Biblioteca.salvarPosicao(indice, de: url) }
        await leitor.carregar(url: url, comecarEm: Biblioteca.posicaoSalva(url))
        carregando = false
    }

    // MARK: - Barra de controles

    private var controles: some View {
        VStack(spacing: 12) {
            if let trecho = leitor.trechoAtual {
                HStack {
                    Text("Página \(trecho.pagina + 1) de \(documento?.pageCount ?? 0)")
                    Spacer()
                    if trecho.pagina != paginaVisivel {
                        Button("Ler a partir da pág. \(paginaVisivel + 1)") {
                            leitor.irParaPagina(paginaVisivel)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 40) {
                Button { leitor.avancar(-1) } label: { Image(systemName: "backward.fill") }
                Button { leitor.alternar() } label: {
                    Image(systemName: leitor.lendo ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                Button { leitor.avancar(1) } label: { Image(systemName: "forward.fill") }
            }
            .font(.title2)
            .disabled(leitor.trechos.isEmpty)

            HStack {
                Image(systemName: "tortoise")
                Slider(value: $leitor.velocidade, in: 0.3...0.65, step: 0.025)
                Image(systemName: "hare")
                Text(String(format: "%.1fx", leitor.velocidade / AVSpeechUtteranceDefaultSpeechRate))
                    .monospacedDigit()
                    .frame(width: 44)
            }
            .font(.caption)
        }
        .padding()
        .background(.bar)
    }

    private var menuDeVozes: some View {
        Menu {
            let vozes = LeitorDeVoz.vozesDisponiveis()
            Picker("Voz", selection: $leitor.vozID) {
                Text("Automática (melhor disponível)").tag(String?.none)
                ForEach(vozes, id: \.identifier) { voz in
                    Text("\(voz.name) · \(rotulo(voz.quality)) · \(voz.language)")
                        .tag(Optional(voz.identifier))
                }
            }
            Section("Para vozes mais naturais, baixe as versões Premium em Ajustes › Acessibilidade › Leitura e Fala (em iOS antigos: Conteúdo Falado) › Vozes › Português.") {}
        } label: {
            Image(systemName: "person.wave.2")
        }
    }

    private func rotulo(_ q: AVSpeechSynthesisVoiceQuality) -> String {
        switch q {
        case .premium: return "Premium"
        case .enhanced: return "Melhorada"
        default: return "Padrão"
        }
    }
}
