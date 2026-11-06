# DeviceLens
Native SwiftUI hardware diagnostics app.
Builds an unsigned iOS .ipa with GitHub Actions on the `devicelens-ipa` branch.
Device model is detected through hw.machine; public APIs supply iOS version, memory, GPU, display resolution, battery, storage. Restricted component manufacturers and serial numbers are not faked.

Build at GitHub -> Actions -> DeviceLens unsigned IPA -> select devicelens-ipa, or push to the branch. Download DeviceLens-unsigned artifact (zip), unzip to find IPA. iOS installation requires signing.
