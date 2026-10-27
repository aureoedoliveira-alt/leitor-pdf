import AVFoundation
import MediaPlayer
import NaturalLanguage
import PDFKit

/// Uma frase do PDF: em que página está, onde fica no texto da página (para destacar) e o que deve ser falado.
struct Trecho: Sendable {
    let pagina: Int
    let intervalo: NSRange
    let fala: String
}

/// Lê o PDF frase por frase com as vozes do próprio iPhone (sem custo e sem internet).
@MainActor
final class LeitorDeVoz: NSObject, ObservableObject {
    @Published private(set) var trechos: [Trecho] = []
    @Published private(set) var indiceAtual = 0
    @Published private(set) var lendo = false

    /// 0.5 é a velocidade normal do iOS. A interface mostra isso como 1,0x.
    @Published var velocidade: Float = UserDefaults.standard.object(forKey: "velocidade") as? Float
        ?? AVSpeechUtteranceDefaultSpeechRate {
        didSet {
            UserDefaults.standard.set(velocidade, forKey: "velocidade")
            if lendo { falarTrechoAtual() }
        }
    }

    @Published var vozID: String? = UserDefaults.standard.string(forKey: "vozID") {
        didSet {
            UserDefaults.standard.set(vozID, forKey: "vozID")
            if lendo { falarTrechoAtual() }
        }
    }

    var trechoAtual: Trecho? { trechos.indices.contains(indiceAtual) ? trechos[indiceAtual] : nil }

    private let sintetizador = AVSpeechSynthesizer()
    private var falaAtual: ObjectIdentifier?
    private var titulo = ""
    var aoMudarPosicao: ((Int) -> Void)?

    override init() {
        super.init()
        sintetizador.delegate = self
        configurarControlesDaTelaBloqueada()
    }

    // MARK: - Vozes

    /// Vozes do idioma escolhido, das melhores (Premium) para as mais simples.
    static func vozesDisponiveis(idioma: String = "pt") -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(idioma) }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    private var vozEscolhida: AVSpeechSynthesisVoice? {
        if let vozID, let voz = AVSpeechSynthesisVoice(identifier: vozID) { return voz }
        return Self.vozesDisponiveis().first ?? AVSpeechSynthesisVoice(language: "pt-BR")
    }

    // MARK: - Carregar o documento

    func carregar(url: URL, comecarEm indice: Int) async {
        titulo = url.deletingPathExtension().lastPathComponent
        let resultado = await Task.detached(priority: .userInitiated) {
            Self.extrairTrechos(de: url)
        }.value
        trechos = resultado
        indiceAtual = min(max(indice, 0), max(resultado.count - 1, 0))
    }

    nonisolated static func extrairTrechos(de url: URL) -> [Trecho] {
        guard let documento = PDFDocument(url: url) else { return [] }
        var lista: [Trecho] = []
        let tokenizador = NLTokenizer(unit: .sentence)

        for numero in 0..<documento.pageCount {
            guard let texto = documento.page(at: numero)?.string, !texto.isEmpty else { continue }
            tokenizador.string = texto
            tokenizador.enumerateTokens(in: texto.startIndex..<texto.endIndex) { faixa, _ in
                let fala = limpar(String(texto[faixa]))
                if fala.contains(where: { $0.isLetter || $0.isNumber }) {
                    lista.append(Trecho(pagina: numero, intervalo: NSRange(faixa, in: texto), fala: fala))
                }
                return true
            }
        }
        return lista
    }

    /// Junta palavras quebradas com hífen no fim da linha e troca quebras de linha por espaço,
    /// para a voz não fazer pausas no meio da frase.
    nonisolated private static func limpar(_ s: String) -> String {
        s.replacingOccurrences(of: "-\n", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Controles

    func alternar() { lendo ? pausar() : tocar() }

    func tocar() {
        guard !trechos.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        lendo = true
        falarTrechoAtual()
    }

    func pausar() {
        lendo = false
        falaAtual = nil
        sintetizador.stopSpeaking(at: .word)
        atualizarTelaBloqueada()
    }

    func avancar(_ passos: Int) {
        irPara(indiceAtual + passos)
    }

    func irPara(_ indice: Int) {
        guard !trechos.isEmpty else { return }
        indiceAtual = min(max(indice, 0), trechos.count - 1)
        aoMudarPosicao?(indiceAtual)
        if lendo { falarTrechoAtual() }
    }

    func irParaPagina(_ pagina: Int) {
        if let i = trechos.firstIndex(where: { $0.pagina >= pagina }) { irPara(i) }
    }

    private func falarTrechoAtual() {
        guard let trecho = trechoAtual else { return }
        if sintetizador.isSpeaking { sintetizador.stopSpeaking(at: .immediate) }

        let fala = AVSpeechUtterance(string: trecho.fala)
        fala.voice = vozEscolhida
        fala.rate = velocidade
        fala.postUtteranceDelay = 0.05
        falaAtual = ObjectIdentifier(fala)
        sintetizador.speak(fala)
        atualizarTelaBloqueada()
    }

    private func terminou(_ id: ObjectIdentifier) {
        // Ignora avisos de frases que já foram interrompidas.
        guard lendo, id == falaAtual else { return }
        if indiceAtual + 1 < trechos.count {
            indiceAtual += 1
            aoMudarPosicao?(indiceAtual)
            falarTrechoAtual()
        } else {
            lendo = false
            atualizarTelaBloqueada()
        }
    }

    // MARK: - Tela bloqueada e fones de ouvido

    private func configurarControlesDaTelaBloqueada() {
        let central = MPRemoteCommandCenter.shared()
        central.playCommand.addTarget { [weak self] _ in self?.tocar(); return .success }
        central.pauseCommand.addTarget { [weak self] _ in self?.pausar(); return .success }
        central.togglePlayPauseCommand.addTarget { [weak self] _ in self?.alternar(); return .success }
        central.nextTrackCommand.addTarget { [weak self] _ in self?.avancar(1); return .success }
        central.previousTrackCommand.addTarget { [weak self] _ in self?.avancar(-1); return .success }
    }

    private func atualizarTelaBloqueada() {
        var info: [String: Any] = [MPMediaItemPropertyTitle: titulo]
        if let trecho = trechoAtual { info[MPMediaItemPropertyArtist] = "Página \(trecho.pagina + 1)" }
        info[MPNowPlayingInfoPropertyPlaybackRate] = lendo ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

extension LeitorDeVoz: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.terminou(id) }
    }
}
