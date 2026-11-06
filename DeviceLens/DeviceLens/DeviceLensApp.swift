import SwiftUI
import UIKit
import Metal
import Darwin

@main
struct DeviceLensApp: App {
    var body: some Scene {
        WindowGroup {
            DeviceLensView().preferredColorScheme(.dark)
        }
    }
}

struct DeviceModel {
    let name: String
    let chip: String
    let screen: String
    static func identify(_ id: String) -> DeviceModel {
        let models: [String: DeviceModel] = [
            "iPhone18,1": .init(name:"iPhone 17 Pro", chip:"A19 Pro", screen:"Super Retina XDR OLED"),
            "iPhone18,2": .init(name:"iPhone 17 Pro Max", chip:"A19 Pro", screen:"Super Retina XDR OLED"),
            "iPhone18,3": .init(name:"iPhone 17", chip:"A19", screen:"Super Retina XDR OLED"),
            "iPhone18,4": .init(name:"iPhone Air", chip:"A19 Pro", screen:"Super Retina XDR OLED"),
            "iPhone17,1": .init(name:"iPhone 16 Pro", chip:"A18 Pro", screen:"Super Retina XDR OLED"),
            "iPhone17,2": .init(name:"iPhone 16 Pro Max", chip:"A18 Pro", screen:"Super Retina XDR OLED"),
            "iPhone17,3": .init(name:"iPhone 16", chip:"A18", screen:"Super Retina XDR OLED"),
            "iPhone17,4": .init(name:"iPhone 16 Plus", chip:"A18", screen:"Super Retina XDR OLED"),
            "iPhone17,5": .init(name:"iPhone 16e", chip:"A18", screen:"OLED"),
            "iPhone16,1": .init(name:"iPhone 15 Pro", chip:"A17 Pro", screen:"Super Retina XDR OLED"),
            "iPhone16,2": .init(name:"iPhone 15 Pro Max", chip:"A17 Pro", screen:"Super Retina XDR OLED"),
            "iPhone15,4": .init(name:"iPhone 15", chip:"A16 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone15,5": .init(name:"iPhone 15 Plus", chip:"A16 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone15,2": .init(name:"iPhone 14 Pro", chip:"A16 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone15,3": .init(name:"iPhone 14 Pro Max", chip:"A16 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,7": .init(name:"iPhone 14", chip:"A15 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,8": .init(name:"iPhone 14 Plus", chip:"A15 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,2": .init(name:"iPhone 13 Pro", chip:"A15 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,3": .init(name:"iPhone 13 Pro Max", chip:"A15 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,4": .init(name:"iPhone 13 mini", chip:"A15 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,5": .init(name:"iPhone 13", chip:"A15 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone14,6": .init(name:"iPhone SE (3. Generation)", chip:"A15 Bionic", screen:"Retina HD LCD"),
            "iPhone13,1": .init(name:"iPhone 12 mini", chip:"A14 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone13,2": .init(name:"iPhone 12", chip:"A14 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone13,3": .init(name:"iPhone 12 Pro", chip:"A14 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone13,4": .init(name:"iPhone 12 Pro Max", chip:"A14 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone12,1": .init(name:"iPhone 11", chip:"A13 Bionic", screen:"Liquid Retina LCD"),
            "iPhone12,3": .init(name:"iPhone 11 Pro", chip:"A13 Bionic", screen:"Super Retina XDR OLED"),
            "iPhone12,5": .init(name:"iPhone 11 Pro Max", chip:"A13 Bionic", screen:"Super Retina XDR OLED")
        ]
        return models[id] ?? .init(name:"iPhone (nicht katalogisiert)", chip:"Unbekannt", screen:"Unbekannt")
    }
}

struct HardwareSnapshot {
    let identifier: String
    let model: DeviceModel
    let ios: String
    let memory: UInt64
    let cpuCount: Int
    let gpu: String
    let totalStorage: Int64
    let freeStorage: Int64
    let battery: Float
    let charging: String
    let lowPower: Bool
    let thermal: String
    let pixels: String
    let refreshRate: Int
    let brightness: Int
    let displayGamut: String
    let uptimeHours: Int
    let capturedAt: Date

    static func formatted(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary)
    }

    static func read() -> HardwareSnapshot {
        UIDevice.current.isBatteryMonitoringEnabled = true
        var length: size_t = 0
        var identifier = UIDevice.current.model
        if sysctlbyname("hw.machine", nil, &length, nil, 0) == 0 && length > 0 && length < 256 {
            var chars = [CChar](repeating: 0, count: Int(length))
            let result = chars.withUnsafeMutableBufferPointer {
                sysctlbyname("hw.machine", $0.baseAddress, &length, nil, 0)
            }
            if result == 0 { identifier = String(cString: chars) }
        }
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = (attrs?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        let screen = UIScreen.main
        let size = screen.nativeBounds.size
        let batteryState: String
        switch UIDevice.current.batteryState {
        case .charging: batteryState = "Lädt"
        case .full: batteryState = "Voll"
        case .unplugged: batteryState = "Nicht am Ladegerät"
        default: batteryState = "Unbekannt"
        }
        let heat: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: heat = "Normal"
        case .fair: heat = "Erhöht"
        case .serious: heat = "Hoch"
        case .critical: heat = "Kritisch"
        @unknown default: heat = "Unbekannt"
        }
        let gamut: String
        switch screen.traitCollection.displayGamut {
        case .P3: gamut = "P3"
        case .SRGB: gamut = "sRGB"
        case .unspecified: gamut = "Unbekannt"
        @unknown default: gamut = "Unbekannt"
        }
        return .init(
            identifier: identifier,
            model: DeviceModel.identify(identifier),
            ios: UIDevice.current.systemName + " " + UIDevice.current.systemVersion,
            memory: ProcessInfo.processInfo.physicalMemory,
            cpuCount: ProcessInfo.processInfo.processorCount,
            gpu: MTLCreateSystemDefaultDevice()?.name ?? "Unbekannt",
            totalStorage: total,
            freeStorage: free,
            battery: UIDevice.current.batteryLevel,
            charging: batteryState,
            lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermal: heat,
            pixels: "\(Int(max(size.width, size.height))) × \(Int(min(size.width, size.height)))",
            refreshRate: screen.maximumFramesPerSecond,
            brightness: Int((screen.brightness * 100).rounded()),
            displayGamut: gamut,
            uptimeHours: Int(ProcessInfo.processInfo.systemUptime / 3600),
            capturedAt: Date()
        )
    }

    var report: String {
        """
        DeviceLens – Hardwarebericht
        Zeitpunkt: \(capturedAt.formatted())
        [LIVE] Modellkennung: \(identifier)
        [MODELL] iPhone: \(model.name)
        [MODELL] Apple-Chip: \(model.chip)
        [MODELL] Displaytechnik: \(model.screen)
        [LIVE] iOS: \(ios)
        [LIVE] RAM: \(HardwareSnapshot.formatted(Int64(memory)))
        [LIVE] CPU-Kerne: \(cpuCount)
        [LIVE] Metal GPU: \(gpu)
        [LIVE] Speicher gesamt: \(HardwareSnapshot.formatted(totalStorage))
        [LIVE] Speicher frei: \(HardwareSnapshot.formatted(freeStorage))
        [LIVE] Native Auflösung: \(pixels)
        [LIVE] Max. Bildrate: \(refreshRate) Hz
        [LIVE] Akku: \(battery < 0 ? "Unbekannt" : "\(Int(battery * 100)) %")
        [LIVE] Ladevorgang: \(charging)
        [LIVE] Temperaturstatus: \(thermal)
        [NICHT VERFÜGBAR] Geräte-Seriennummer
        [NICHT VERFÜGBAR] Display-Hersteller / Display-Seriennummer
        [NICHT VERFÜGBAR] NAND-Hersteller / RAM-Hersteller
        Keine privaten APIs, keine erfundenen Herstellerangaben.
        """
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let source: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).foregroundStyle(.white.opacity(0.67))
                Spacer(minLength: 8)
                Text(value).foregroundStyle(.white).multilineTextAlignment(.trailing)
                    .fontWeight(.semibold).textSelection(.enabled)
            }
            Text(source).font(.system(size: 10, weight: .bold))
                .foregroundStyle(source == "LIVE" ? .mint : source == "MODELL" ? .orange : .gray)
        }
        .font(.system(size: 13))
        .padding(.vertical, 9)
    }
}

struct HardwareCard<Content: View>: View {
    let label: String
    let symbol: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: symbol).font(.headline).foregroundStyle(tint)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(
            LinearGradient(colors: [tint.opacity(0.17), Color(red:0.09,green:0.11,blue:0.16)],
                           startPoint:.topLeading, endPoint:.bottomTrailing)
        ))
        .overlay(RoundedRectangle(cornerRadius:22).stroke(tint.opacity(0.25)))
    }
}

struct DeviceLensView: View {
    @State private var snapshot = HardwareSnapshot.read()
    private let bg = Color(red:0.03,green:0.04,blue:0.075)

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment:.leading, spacing:15) {
                        VStack(alignment:.leading, spacing:7) {
                            Text("AUTOMATISCH ERKANNT").font(.caption.bold()).foregroundStyle(.cyan)
                            Text(snapshot.model.name).font(.largeTitle.bold())
                            Text(snapshot.identifier).foregroundStyle(.white.opacity(0.6))
                            Text(snapshot.ios).font(.footnote).foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius:22).fill(.blue.opacity(0.18)))

                        HardwareCard(label:"Display",symbol:"display",tint:.red) {
                            InfoRow(title:"Bildschirm",value:snapshot.model.screen,source:"MODELL")
                            InfoRow(title:"Native Auflösung",value:snapshot.pixels + " px",source:"LIVE")
                            InfoRow(title:"Panel-Hersteller",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                        HardwareCard(label:"CPU & RAM",symbol:"cpu",tint:.purple) {
                            InfoRow(title:"Apple-Chip",value:snapshot.model.chip,source:"MODELL")
                            InfoRow(title:"Prozessorkerne",value:"\(snapshot.cpuCount)",source:"LIVE")
                            InfoRow(title:"Arbeitsspeicher",value:HardwareSnapshot.formatted(Int64(snapshot.memory)),source:"LIVE")
                            InfoRow(title:"RAM-Hersteller",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                        HardwareCard(label:"Speicher",symbol:"internaldrive",tint:.orange) {
                            InfoRow(title:"Gesamt",value:HardwareSnapshot.formatted(snapshot.totalStorage),source:"LIVE")
                            InfoRow(title:"Frei",value:HardwareSnapshot.formatted(snapshot.freeStorage),source:"LIVE")
                            InfoRow(title:"NAND-Hersteller",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                        HardwareCard(label:"Akku",symbol:"battery.100",tint:.green) {
                            InfoRow(title:"Ladestand",value:snapshot.battery < 0 ? "Unbekannt" : "\(Int(snapshot.battery * 100)) %",source:"LIVE")
                            InfoRow(title:"Status",value:snapshot.charging,source:"LIVE")
                        }
                        Text("LIVE = abgefragt  ·  MODELL = Katalogdaten  ·  NICHT VERFÜGBAR = iOS sperrt den Zugriff.")
                            .font(.caption2).foregroundStyle(.gray)
                    }
                    .padding(16)
                }
                .background(bg)
                .navigationTitle("DeviceLens")
                .toolbar {
                    ToolbarItem(placement:.topBarTrailing) {
                        Button { snapshot = HardwareSnapshot.read() } label: { Image(systemName:"arrow.clockwise") }
                    }
                    ToolbarItem(placement:.topBarTrailing) {
                        ShareLink(item:snapshot.report) { Image(systemName:"square.and.arrow.up") }
                    }
                }
                .refreshable { snapshot = HardwareSnapshot.read() }
            }
            .tabItem { Label("Übersicht", systemImage:"square.grid.2x2.fill") }

            NavigationStack {
                ScrollView {
                    VStack(spacing:15) {
                        HardwareCard(label:"System",symbol:"iphone",tint:.blue) {
                            InfoRow(title:"Modell",value:snapshot.model.name,source:"MODELL")
                            InfoRow(title:"Hardwarekennung",value:snapshot.identifier,source:"LIVE")
                            InfoRow(title:"iOS",value:snapshot.ios,source:"LIVE")
                            InfoRow(title:"Seriennummer",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                        HardwareCard(label:"Display",symbol:"rectangle.on.rectangle",tint:.red) {
                            InfoRow(title:"Technologie",value:snapshot.model.screen,source:"MODELL")
                            InfoRow(title:"Auflösung",value:snapshot.pixels,source:"LIVE")
                            InfoRow(title:"Max. Bildwiederholrate",value:"\(snapshot.refreshRate) Hz",source:"LIVE")
                            InfoRow(title:"Helligkeitsregler",value:"\(snapshot.brightness) %",source:"LIVE")
                            InfoRow(title:"Farbraum",value:snapshot.displayGamut,source:"LIVE")
                            InfoRow(title:"Display-Seriennummer",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                        HardwareCard(label:"Chips",symbol:"cpu",tint:.purple) {
                            InfoRow(title:"Apple-Chip",value:snapshot.model.chip,source:"MODELL")
                            InfoRow(title:"Metal GPU",value:snapshot.gpu,source:"LIVE")
                            InfoRow(title:"RAM",value:HardwareSnapshot.formatted(Int64(snapshot.memory)),source:"LIVE")
                            InfoRow(title:"RAM-/NAND-Lieferant",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                            InfoRow(title:"TLC/QLC-Speichertyp",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                        HardwareCard(label:"Akku & System",symbol:"battery.100",tint:.green) {
                            InfoRow(title:"Ladestand",value:snapshot.battery < 0 ? "Unbekannt" : "\(Int(snapshot.battery * 100)) %",source:"LIVE")
                            InfoRow(title:"Ladezustand",value:snapshot.charging,source:"LIVE")
                            InfoRow(title:"Stromsparmodus",value:snapshot.lowPower ? "Ein":"Aus",source:"LIVE")
                            InfoRow(title:"Wärmestatus",value:snapshot.thermal,source:"LIVE")
                            InfoRow(title:"Laufzeit",value:"\(snapshot.uptimeHours) Stunden",source:"LIVE")
                            InfoRow(title:"Ladezyklen",value:"Nicht auslesbar",source:"NICHT VERFÜGBAR")
                        }
                    }.padding(16)
                }.background(bg)
                .navigationTitle("Hardware")
            }
            .tabItem { Label("Hardware",systemImage:"cpu") }

            NavigationStack {
                DiagnosticImportView()
            }
            .tabItem { Label("Diagnose",systemImage:"doc.text.magnifyingglass") }

            NavigationStack {
                ScrollView {
                    VStack(alignment:.leading,spacing:16) {
                        HardwareCard(label:"Hinweise",symbol:"info.circle",tint:.cyan) {
                            Text("DeviceLens erkennt das iPhone durch seine Hardwarekennung. LIVE-Werte kommen aus System-APIs, MODELL-Werte aus der eingebauten Modellliste.")
                            Text("Apple erlaubt gewöhnlichen Apps nicht, den Hersteller des tatsächlich verbauten Displays, NAND- oder RAM-Chips oder die Geräteseriennummer auszulesen. Diese Angaben werden deshalb nicht erfunden. Unter Diagnose kannst du vorhandene Analysedateien lokal auf Hardware-Hinweise prüfen lassen.")
                        }
                        HardwareCard(label:"Datenschutz",symbol:"lock.shield",tint:.green) {
                            Text("Alle Daten bleiben auf dem Gerät. Es gibt keine Accounts, Werbung oder Internetabfragen.")
                        }
                        Text("Version 1.1").foregroundStyle(.gray).font(.footnote)
                    }.padding(16)
                }.background(bg)
                .navigationTitle("Über die App")
            }
            .tabItem { Label("Info",systemImage:"info.circle") }
        }
        .tint(.cyan)
        .onReceive(NotificationCenter.default.publisher(for:UIApplication.didBecomeActiveNotification)) { _ in
            snapshot = HardwareSnapshot.read()
        }
    }
}
