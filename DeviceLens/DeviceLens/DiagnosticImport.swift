import SwiftUI
import UniformTypeIdentifiers
import Foundation

// Analyzes user-selected files locally. The app has no network calls and does not persist raw logs.
// Vendor prefix mappings are community-sourced hints, not Apple-verified manufacturer certificates.
struct DiagnosticFinding: Identifiable {
    let id = UUID()
    let category: String
    let label: String
    let value: String
    let detail: String
    let confidence: String
}

struct ImportedDiagnosis: Identifiable {
    let id = UUID()
    let filename: String
    let findings: [DiagnosticFinding]
    let note: String
}

enum DiagnosticScanner {
    private static let panelVendors: [String:String] = [
        "G9N":"Samsung Display", "G9P":"Samsung Display", "G9Q":"Samsung Display",
        "GH3":"LG Display", "GVC":"LG Display", "G9C":"LG Display"
    ]

    static func scan(_ data: Data, filename: String) -> ImportedDiagnosis {
        let loweredName = filename.lowercased()
        if loweredName.hasSuffix(".zip") || loweredName.hasSuffix(".gz") ||
            loweredName.hasSuffix(".tgz") || loweredName.hasSuffix(".tar") {
            return ImportedDiagnosis(filename: filename, findings: [],
                note: "Archiv erkannt. Bitte zuerst in der Dateien-App entpacken. Wähle danach eine einzelne Textdatei aus dem Ordner ioreg/IODeviceTree oder eine .ips-, .json-, .plist- bzw. .log-Datei.")
        }
        let content: String
        if data.starts(with: Array("bplist".utf8)) {
            if let object = try? PropertyListSerialization.propertyList(from: data, format: nil) {
                var output: [String] = []
                flatten(object, prefix: "", into: &output)
                content = output.joined(separator: "\n")
            } else {
                return ImportedDiagnosis(filename: filename, findings: [],
                    note: "Binäre plist-Datei konnte nicht gelesen werden.")
            }
        } else if let decoded = String(data: data, encoding: .utf8) {
            content = decoded
        } else if let decoded = String(data: data, encoding: .utf16) {
            content = decoded
        } else if let decoded = String(data: data, encoding: .isoLatin1) {
            content = decoded
        } else {
            return ImportedDiagnosis(filename: filename, findings: [],
                note: "Dieses Dateiformat ist nicht als Text auswertbar. Bitte eine entpackte Text-/Plist-Datei auswählen.")
        }

        let lines = content.components(separatedBy: .newlines)
        var matches: [DiagnosticFinding] = []
        var panelCodes = Set<String>()
        var panelKeyFound = false
        var ramKeyFound = false
        var nandKeyFound = false
        var flashTypeFound = false

        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            let context = String(line.prefix(340)) + (index + 1 < lines.count ? " " + String(lines[index + 1].prefix(160)) : "")

            if lower.contains("raw-panel") || lower.contains("panel-serial") ||
                lower.contains("display-serial") || lower.contains("panel_serial") {
                panelKeyFound = true
                if let code = detectPanelPrefix(context) { panelCodes.insert(code) }
            }

            if lower.contains("dram-vendor") || lower.contains("ram-vendor") ||
                lower.contains("memory-vendor") || lower.contains("dram_vendor") ||
                lower.contains("ram_vendor") {
                if !ramKeyFound {
                    ramKeyFound = true
                    let vendor = detectManufacturer(context, names: ["Micron", "Samsung", "SK Hynix", "Hynix", "Nanya", "Elpida"])
                    matches.append(DiagnosticFinding(category: "RAM", label: "RAM-Hersteller",
                        value: vendor ?? "Kennung vorhanden, Hersteller unklar",
                        detail: "Hinweis aus einem importierten Diagnoseschlüssel, keine direkte Hardwareabfrage.",
                        confidence: "LOG-HINWEIS"))
                }
            }
            if lower.contains("nand-vendor") || lower.contains("storage-vendor") ||
                lower.contains("flash-vendor") || lower.contains("nand_vendor") ||
                lower.contains("storage_vendor") || lower.contains("flash_vendor") {
                if !nandKeyFound {
                    nandKeyFound = true
                    let vendor = detectManufacturer(context, names: ["Kioxia", "Toshiba", "Samsung", "Western Digital", "SanDisk", "SK Hynix", "Hynix", "Micron"])
                    matches.append(DiagnosticFinding(category: "Speicher", label: "NAND-Hersteller",
                        value: vendor ?? "Kennung vorhanden, Hersteller unklar",
                        detail: "Hinweis aus einem importierten Diagnoseschlüssel; nicht zwingend der Hersteller des Speicherchips.",
                        confidence: "LOG-HINWEIS"))
                }
            }
            if lower.contains("nand-type") || lower.contains("flash-type") ||
                lower.contains("nand_type") || lower.contains("flash_type") ||
                lower.contains("cell-type") {
                if !flashTypeFound {
                    flashTypeFound = true
                    let type = detectStorageType(context)
                    matches.append(DiagnosticFinding(category: "Speicher", label: "Speicherzelltyp",
                        value: type ?? "Kennung vorhanden, Typ unklar",
                        detail: "Nur angezeigt, wenn eine entsprechende Log-Bezeichnung vorkommt.",
                        confidence: "LOG-HINWEIS"))
                }
            }
        }
        if panelCodes.count == 1, let code = panelCodes.first {
            let vendor = panelVendors[code] ?? "Unbekannter Hersteller"
            matches.insert(DiagnosticFinding(category: "Display", label: "Panel-Kennung", value: code,
                detail: "Aus raw-panel-serial-number bzw. einem verwandten Diagnosefeld.",
                confidence: "LOG-HINWEIS"), at: 0)
            matches.insert(DiagnosticFinding(category: "Display", label: "Displayhersteller (Indiz)",
                value: vendor,
                detail: "Community-Zuordnung für den Prefix " + code + ". Nicht von Apple bestätigt; diese Kennung kann veraltet oder mehrdeutig sein.",
                confidence: "UNBESTÄTIGT"), at: 1)
        } else if panelCodes.count > 1 {
            matches.insert(DiagnosticFinding(category: "Display", label: "Panel-Hinweise",
                value: panelCodes.sorted().joined(separator: ", "),
                detail: "Mehrere Kennungen gefunden. Es ist nicht klar, welche zur internen Displayeinheit gehört.",
                confidence: "NICHT EINDEUTIG"), at: 0)
        } else if panelKeyFound {
            matches.insert(DiagnosticFinding(category: "Display", label: "Panel-Daten",
                value: "Feld gefunden, Code nicht erkannt",
                detail: "Die App erkennt bislang keine eindeutige Seriennummer/Herstellerkennung aus diesem Wert.",
                confidence: "NICHT EINDEUTIG"), at: 0)
        }
        let note = matches.isEmpty
            ? "Keine unterstützten Display-, RAM- oder NAND-Hinweise gefunden. Viele .ips-Dateien enthalten keine Bauteilinformationen. Probiere die entpackte Datei ioreg/IODeviceTree einer Sysdiagnose. Auf neueren iOS-Versionen können diese Felder fehlen."
            : "Es wurden " + String(matches.count) + " Hinweise gefunden. Ein Logeintrag ist kein Nachweis der Bauteilidentität; gefundene Namen können unvollständig oder irreführend sein."
        return ImportedDiagnosis(filename: filename, findings: matches, note: note)
    }

    private static func detectPanelPrefix(_ content: String) -> String? {
        let upper = content.uppercased()
        // ASCII serial number, including a quoted value in an IORegistry dump
        for code in panelVendors.keys.sorted() {
            if upper.contains(code) { return code }
        }
        // Hex-encoded ASCII values, e.g. <473951...> = "G9Q..."
        if let regex = try? NSRegularExpression(pattern: "(?:[0-9A-Fa-f]{2}[\\s,:-]*){3,}") {
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            for match in regex.matches(in: content, range: range).prefix(12) {
                guard let r = Range(match.range, in: content) else { continue }
                let hex = content[r].filter { $0.isHexDigit }
                for code in panelVendors.keys.sorted() {
                    let prefix = code.utf8.map { String(format: "%02X", $0) }.joined()
                    if hex.uppercased().hasPrefix(prefix) { return code }
                }
            }
        }
        return nil
    }

    private static func detectManufacturer(_ content: String, names: [String]) -> String? {
        for name in names {
            if content.range(of: name, options: .caseInsensitive) != nil { return name }
        }
        return nil
    }

    private static func detectStorageType(_ content: String) -> String? {
        let content = content.uppercased()
        for type in ["QLC","TLC","MLC","SLC"] {
            if content.range(of: "\\b" + type + "\\b", options: .regularExpression) != nil { return type }
        }
        return nil
    }

    private static func flatten(_ object: Any, prefix: String, into lines: inout [String]) {
        if lines.count >= 8000 { return }
        if let dict = object as? [String: Any] {
            for (key, value) in dict {
                flatten(value, prefix: prefix.isEmpty ? key : prefix + "." + key, into: &lines)
                if lines.count >= 8000 { break }
            }
        } else if let array = object as? [Any] {
            for (i, value) in array.prefix(100).enumerated() {
                flatten(value, prefix: prefix + "[" + String(i) + "]", into: &lines)
            }
        } else if let bytes = object as? Data {
            let printable = String(data: bytes.prefix(100), encoding: .utf8) ?? ""
            let hex = bytes.prefix(100).map { String(format: "%02X", $0) }.joined()
            lines.append(prefix + ": " + printable + " <" + hex + ">")
        } else {
            lines.append(prefix + ": " + String(describing: object).prefix(500))
        }
    }
}

struct DiagnosticImportView: View {
    @State private var isImporting = false
    @State private var reports: [ImportedDiagnosis] = []
    @State private var status = ""
    private let darkBackground = Color(red: 0.03, green: 0.04, blue: 0.075)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Erweiterte Analyse", systemImage: "doc.text.magnifyingglass")
                        .font(.title2.bold()).foregroundStyle(.cyan)
                    Text("Importiere eine iPhone-Analysedatei. DeviceLens sucht darin lokal nach Panel-, RAM- und NAND-Kennungen.")
                        .foregroundStyle(.white.opacity(0.8))
                    Button {
                        isImporting = true
                    } label: {
                        Label("Diagnosedateien auswählen", systemImage: "square.and.arrow.down")
                            .fontWeight(.semibold())
                            .frame(maxWidth: .infinity).padding(14)
                    }
                    .buttonStyle(.borderedProminent).tint(.blue)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.17)))

                if !status.isEmpty {
                    Text(status).font(.footnote).foregroundStyle(.orange)
                }

                ForEach(reports) { report in
                    VStack(alignment: .leading, spacing: 12) {
                        Label(report.filename, systemImage: "doc")
                            .font(.headline).lineLimit(2)
                        ForEach(report.findings) { finding in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(finding.category.uppercased())
                                    .font(.caption2.bold()).foregroundStyle(.cyan)
                                HStack(alignment: .top) {
                                    Text(finding.label).foregroundStyle(.white.opacity(0.7))
                                    Spacer(minLength: 8)
                                    Text(finding.value).fontWeight(.semibold()).multilineTextAlignment(.trailing)
                                }
                                .font(.subheadline)
                                Text(finding.confidence + " · " + finding.detail)
                                    .font(.caption).foregroundStyle(.white.opacity(0.55))
                            }
                            Divider().overlay(.white.opacity(0.08))
                        }
                        Text(report.note).font(.footnote).foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.065)))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("So kommst du an die Daten").font(.headline)
                    Text("1. Einstellungen → Datenschutz & Sicherheit → Analyse & Verbesserungen → Analysedaten.")
                    Text("2. Falls vorhanden, eine Sysdiagnose über „In Dateien sichern“ exportieren.")
                    Text("3. Archiv in der Dateien-App entpacken. In der Sysdiagnose nach „ioreg/IODeviceTree“ suchen.")
                    Text("4. Diese Datei hier auswählen; alternativ einzelne .ips-, .log-, .json- oder .plist-Dateien importieren.")
                    Text("Die App liest keine Archive direkt. Auf neueren iOS-Versionen fehlen manche Hardwarefelder auch in Sysdiagnosen.")
                        .font(.caption).foregroundStyle(.orange)
                }
                .font(.subheadline)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.065)))

                Label("Privat: Alles wird auf deinem iPhone ausgewertet. Die Rohdatei wird nicht gespeichert oder hochgeladen.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.mint)
            }
            .padding(16)
        }
        .background(darkBackground)
        .navigationTitle("Diagnose-Import")
        .fileImporter(isPresented: $isImporting,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: true) { result in
            switch result {
            case .failure(let error):
                status = "Import fehlgeschlagen: " + error.localizedDescription
            case .success(let urls):
                var next: [ImportedDiagnosis] = []
                var skipped = 0
                for url in urls.prefix(8) {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                        if size > 24_000_000 { skipped += 1; continue }
                        let data = try Data(contentsOf: url)
                        if data.count > 24_000_000 { skipped += 1; continue }
                        next.append(DiagnosticScanner.scan(data, filename: url.lastPathComponent))
                    } catch {
                        next.append(ImportedDiagnosis(filename: url.lastPathComponent,
                            findings: [], note: "Konnte Datei nicht öffnen: " + error.localizedDescription))
                    }
                }
                reports = next
                status = skipped > 0 ? String(skipped) + " Datei(en) über 24 MB übersprungen. Bitte ioreg/IODeviceTree statt des kompletten Sysdiagnose-Archivs importieren." : ""
            }
        }
    }
}
