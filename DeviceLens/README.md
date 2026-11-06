# DeviceLens 1.1
Native SwiftUI iPhone diagnostics plus local file import. The app automatically detects the device model via hw.machine, while hardware details come from public APIs.

New tab **Diagnose**: Import extracted plain-text sysdiagnose IORegistry files like ioreg/IODeviceTree, .ips, .json, .plist or .log files. Scan locally for raw-panel-serial-number and related keys; decode ASCII/hex prefix G9Q/G9N/G9P (community-listed as Samsung) or GH3/GVC/G9C (community-listed as LG). Manufacturer mappings are *hints*, never proof. Detect only explicitly labeled RAM/NAND vendor and flash technology fields. No upload, no raw-data retention. ZIP, tar and gz archives must be unpacked first. Files above 24 MB are rejected.

Build in GitHub Actions on branch devicelens-ipa, download artifact DeviceLens-unsigned, unpack artifact ZIP to retrieve unsigned IPA. Installation requires separate code signing. UI not tested on physical iPhone.
