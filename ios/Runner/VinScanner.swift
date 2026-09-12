import AVFoundation
import CoreImage
import Flutter
import UIKit
import Vision

// Mirrors ListingVin's syntactic rules only. Dart remains the final validator.
// Never substitute ambiguous OCR characters or concatenate unrelated observations.
struct VinTextSpan {
  let text: String
  let box: CGRect
}

enum VinCandidates {
  static func normalize(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "-", with: "").uppercased()
  }

  static func isValid(_ value: String) -> Bool {
    value.utf8.count == 17 && value.range(of: "^[A-HJ-NPR-Z0-9]{17}$", options: .regularExpression) != nil
  }

  static func extract(_ observations: [String]) -> Set<String> {
    extract(spans: observations.map { VinTextSpan(text: $0, box: .null) })
  }

  static func extract(spans: [VinTextSpan]) -> Set<String> {
    var candidates = Set<String>()
    for span in spans {
      candidates.formUnion(extractSingle(span.text))
    }
    for joined in joinNearby(spans) {
      candidates.formUnion(extractSingle(joined))
    }
    return candidates
  }

  static func extractSingle(_ raw: String) -> Set<String> {
    let patterns = [
      "(?<![A-Z0-9])[A-Z0-9]{17}(?![A-Z0-9])",
      "(?<![A-Z0-9])[A-Z0-9](?:[ -]+[A-Z0-9])+(?![A-Z0-9])",
    ]
    let expressions = patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    let separators = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -")).inverted
    let text = raw.uppercased()
    var fragments = text.components(separatedBy: separators)
    for expression in expressions {
      for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
        guard let range = Range(match.range, in: text) else { continue }
        fragments.append(String(text[range]))
      }
    }
    var candidates = Set<String>()
    for fragment in fragments {
      let value = normalize(fragment)
      if isValid(value) { candidates.insert(value) }
    }
    return candidates
  }

  /// Same-line, spatially adjacent fragments only. Distant document text is ignored.
  static func joinNearby(_ spans: [VinTextSpan]) -> [String] {
    let spatial = spans.filter { !$0.box.isNull && $0.box.width > 0 && $0.box.height > 0 && !$0.text.isEmpty }
    guard spatial.count >= 2 else { return [] }
    let ordered = spatial.sorted {
      if abs($0.box.midY - $1.box.midY) > 0.02 { return $0.box.midY > $1.box.midY }
      return $0.box.minX < $1.box.minX
    }
    var lines: [[VinTextSpan]] = []
    for span in ordered {
      if var line = lines.last {
        let reference = line[0]
        let tolerance = max(reference.box.height, span.box.height) * 0.75
        if abs(reference.box.midY - span.box.midY) <= tolerance {
          line.append(span)
          lines[lines.count - 1] = line
          continue
        }
      }
      lines.append([span])
    }
    var joined: [String] = []
    for line in lines {
      let run = line.sorted { $0.box.minX < $1.box.minX }
      guard run.count >= 2 else { continue }
      var parts = [run[0].text]
      var lastMaxX = run[0].box.maxX
      let maxGap = max(0.06, run[0].box.height * 1.4)
      for span in run.dropFirst() {
        if span.box.minX - lastMaxX > maxGap {
          if parts.count >= 2 { joined.append(parts.joined()) }
          parts = [span.text]
        } else {
          parts.append(span.text)
        }
        lastMaxX = max(lastMaxX, span.box.maxX)
      }
      if parts.count >= 2 { joined.append(parts.joined()) }
    }
    return joined
  }
}

/// Unique-candidate history: confirm when one VIN appears in 2 of the last 3 suitable analyses.
struct VinStability {
  private var recent: [String] = []
  private let window = 3
  private let needed = 2

  mutating func observe(_ candidates: Set<String>) -> String? {
    guard candidates.count == 1, let candidate = candidates.first else { return confirmed() }
    recent.append(candidate)
    if recent.count > window { recent.removeFirst() }
    return confirmed()
  }

  mutating func reset() { recent = [] }

  private func confirmed() -> String? {
    guard recent.count >= needed else { return nil }
    var counts: [String: Int] = [:]
    for item in recent { counts[item, default: 0] += 1 }
    let winners = counts.filter { $0.value >= needed }
    guard winners.count == 1, counts.count == 1, let vin = winners.keys.first else { return nil }
    return vin
  }
}

enum VinScanPass: Equatable {
  case primary
  case expanded
  case still
}

struct VinScanSchedule {
  private(set) var index = 0
  private(set) var unsuccessful = 0

  mutating func nextLive() -> VinScanPass {
    index += 1
    if unsuccessful >= 3 && index % 4 == 0 { return .expanded }
    return .primary
  }

  mutating func markUnsuccessful() { unsuccessful += 1 }
  mutating func reset() { index = 0; unsuccessful = 0 }
}

enum VinRoi {
  static func expanded(_ primary: CGRect) -> CGRect {
    let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
    return primary.insetBy(dx: -0.10, dy: -0.16).intersection(unit)
  }
}

enum VinHintKind: Equatable {
  case defaultHint
  case closer
  case glare
}

enum VinHintSchedule {
  static func kind(unsuccessful: Int) -> VinHintKind {
    guard unsuccessful >= 8 else { return .defaultHint }
    return ((unsuccessful - 8) / 8) % 2 == 0 ? .closer : .glare
  }
}

enum VinBarcode {
  static let preferred: [VNBarcodeSymbology] = [
    .code39, .code128, .dataMatrix, .pdf417, .qr, .aztec,
  ]

  static func enabled(from supported: [VNBarcodeSymbology]) -> [VNBarcodeSymbology] {
    preferred.filter(supported.contains)
  }
}

enum VinStillResult {
  static func accept(_ candidates: Set<String>) -> String? {
    guard candidates.count == 1, let vin = candidates.first, VinCandidates.isValid(vin) else { return nil }
    return vin
  }
}

enum VinCameraZoom {
  static func factor(minimum: CGFloat, maximum: CGFloat) -> CGFloat {
    Swift.min(Swift.max(1.35, minimum), Swift.min(1.6, maximum))
  }
}

enum VinOcrSpans {
  static func from(
    _ observations: [VNRecognizedTextObservation],
    top: Int,
    minConfidence: Float
  ) -> [VinTextSpan] {
    let count = max(1, top)
    return observations.flatMap { observation in
      observation.topCandidates(count).compactMap { candidate -> VinTextSpan? in
        guard candidate.confidence >= minConfidence else { return nil }
        return VinTextSpan(text: candidate.string, box: observation.boundingBox)
      }
    }
  }
}

enum VinOcrDecision {
  /// Primary extract wins immediately. Fallback alternatives are ignored unless primary is empty.
  static func resolve(primary: Set<String>, fallback: Set<String>) -> Set<String> {
    primary.isEmpty ? fallback : primary
  }
}

enum VinFallbackSchedule {
  /// After 6 failed live cycles, run an enhanced pass on every 5th miss (~2s), never on the happy path.
  static func shouldEnhance(unsuccessful: Int) -> Bool {
    unsuccessful >= 6 && (unsuccessful - 6) % 5 == 0
  }
}

enum VinFallbackScale {
  static let factor: CGFloat = 1.45
}

enum VinFallbackCrop {
  /// Vision/CI normalized ROI, origin lower-left.
  static func pixelRect(roi: CGRect, imageExtent: CGRect) -> CGRect {
    let rect = CGRect(
      x: imageExtent.minX + roi.minX * imageExtent.width,
      y: imageExtent.minY + roi.minY * imageExtent.height,
      width: roi.width * imageExtent.width,
      height: roi.height * imageExtent.height
    ).integral
    return rect.intersection(imageExtent)
  }
}

enum VinFallbackRender {
  static func mildContrastGray(_ image: CIImage) -> CIImage {
    let gray = image.applyingFilter("CIColorMonochrome", parameters: [
      kCIInputColorKey: CIColor(red: 0.92, green: 0.92, blue: 0.92),
      kCIInputIntensityKey: 1,
    ])
    return gray.applyingFilter("CIColorControls", parameters: [
      kCIInputSaturationKey: 0,
      kCIInputContrastKey: 1.18,
      kCIInputBrightnessKey: 0.02,
    ])
  }
}

enum VinFallbackChain {
  static func firstNonEmpty(_ batches: [Set<String>]) -> Set<String> {
    batches.first { !$0.isEmpty } ?? []
  }
}

enum VinFallbackContext {
  static let ci = CIContext(options: [.cacheIntermediates: false])
}

/// Logical VIN scan rectangle. Decorative chrome must use this frame; do not resize for aesthetics.
enum VinGuideLayout {
  static func logicalFrame(in bounds: CGRect) -> CGRect {
    CGRect(x: 24, y: bounds.height * 0.31, width: max(1, bounds.width - 48), height: 100)
  }
}

enum VinScannerPresenter {
  static func top(from controller: UIViewController?) -> UIViewController? {
    guard let controller else { return nil }
    if let presented = controller.presentedViewController { return top(from: presented) }
    if let navigation = controller as? UINavigationController {
      return top(from: navigation.visibleViewController ?? navigation.topViewController)
    }
    if let tabs = controller as? UITabBarController {
      return top(from: tabs.selectedViewController)
    }
    return controller
  }

  static func host(preferred: UIViewController?, windows: [UIWindow]) -> UIViewController? {
    if let attached = attached(top(from: preferred)) { return attached }
    return host(in: windows)
  }

  static func host(in windows: [UIWindow]) -> UIViewController? {
    let usable = windows.filter { !$0.isHidden && $0.alpha > 0 }
    let window = usable.first(where: \.isKeyWindow) ?? usable.first { $0.rootViewController != nil }
    return attached(top(from: window?.rootViewController))
  }

  static func currentWindows(application: UIApplication = .shared) -> [UIWindow] {
    let scenes = application.connectedScenes.compactMap { $0 as? UIWindowScene }
    let active = scenes.filter { $0.activationState == .foregroundActive }
    return (active.isEmpty ? scenes : active).flatMap(\.windows)
  }

  private static func attached(_ controller: UIViewController?) -> UIViewController? {
    guard let controller else { return nil }
    controller.loadViewIfNeeded()
    return controller.view.window == nil ? nil : controller
  }
}

final class VinScannerPlugin: NSObject, FlutterPlugin {
  private weak var preferredHost: UIViewController?
  private var scanner: VinScannerController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = VinScannerPlugin()
    instance.preferredHost = registrar.viewController
    let channel = FlutterMethodChannel(name: "carzon/vin_scanner", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "scanVin" else { result(FlutterMethodNotImplemented); return }
    let present = { [weak self] in
      guard let self else {
        result(FlutterError(code: "no_presenter", message: nil, details: nil))
        return
      }
      self.presentScanner(result: result, arguments: call.arguments)
    }
    if Thread.isMainThread { present() } else { DispatchQueue.main.async(execute: present) }
  }

  private func presentScanner(result: @escaping FlutterResult, arguments: Any?) {
    let keys = ["title", "instruction", "hint", "initializing", "found", "use", "again", "close",
                "deniedTitle", "denied", "unavailableTitle", "unavailable", "settings",
                "torchOn", "torchOff", "retry"]
    guard let strings = arguments as? [String: String],
          keys.allSatisfy({ !(strings[$0] ?? "").isEmpty }),
          scanner == nil else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    guard let host = VinScannerPresenter.host(
      preferred: preferredHost,
      windows: VinScannerPresenter.currentWindows()
    ) else {
      result(FlutterError(code: "no_presenter", message: nil, details: nil))
      return
    }
    let controller = VinScannerController(strings: strings)
    controller.onFinish = { [weak self, weak controller] vin in
      controller?.dismiss(animated: true) {
        self?.scanner = nil
        result(vin)
      }
    }
    scanner = controller
    controller.modalPresentationStyle = .fullScreen
    host.present(controller, animated: true)
  }
}

final class VinScannerController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  var onFinish: ((String?) -> Void)?
  private enum State { case initializing, scanning, confirmation(String), denied, unavailable }
  private var state = State.initializing
  private let strings: [String: String]
  private let session = AVCaptureSession()
  private let output = AVCaptureVideoDataOutput()
  // All capture, Vision, ROI and stability state is confined to this serial queue.
  private let captureQueue = DispatchQueue(label: "carzon.vin.capture", qos: .userInitiated)
  private var device: AVCaptureDevice?
  private var configured = false
  private var recognitionEnabled = false
  private var terminated = false
  private var analyzing = false
  private var lastAnalysis = 0.0
  private var stability = VinStability()
  private var schedule = VinScanSchedule()
  private var primaryRoi = CGRect(x: 0.05, y: 0.4, width: 0.9, height: 0.2)
  private var expandedRoi = CGRect(x: 0, y: 0.24, width: 1, height: 0.52)
  private var latestPixelBuffer: CVPixelBuffer?
  private var stillRequested = false
  private var lastHint = VinHintKind.defaultHint
  private var finished = false
  private var requestingPermission = false
  private var torchEnabled = false
  private var preview: AVCaptureVideoPreviewLayer!
  private let topFade = CAGradientLayer()
  private let bottomFade = CAGradientLayer()
  private let guide = UIView()
  private let guideOutline = CAShapeLayer()
  private let guideCorners = CAShapeLayer()
  private let focusRing = UIView()
  private let headerBar = UIStackView()
  private let liveChrome = UIStackView()
  private let sheet = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let titleLabel = UILabel()
  private let instruction = UILabel()
  private let detail = UILabel()
  private let sheetTitle = UILabel()
  private let sheetBody = UILabel()
  private let vinLabel = UILabel()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let stillSpinner = UIActivityIndicatorView(style: .medium)
  private let closeButton = UIButton(type: .system)
  private let torchButton = UIButton(type: .system)
  private let stillButton = UIButton(type: .system)
  private let primary = UIButton(type: .system)
  private let secondary = UIButton(type: .system)
  private var focusResume: DispatchWorkItem?

  init(strings: [String: String]) { self.strings = strings; super.init(nibName: nil, bundle: nil) }
  required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = .resizeAspectFill
    view.layer.addSublayer(preview)
    topFade.colors = [
      UIColor.black.withAlphaComponent(0.45).cgColor,
      UIColor.black.withAlphaComponent(0).cgColor,
    ]
    bottomFade.colors = [
      UIColor.black.withAlphaComponent(0).cgColor,
      UIColor.black.withAlphaComponent(0.42).cgColor,
    ]
    view.layer.addSublayer(topFade)
    view.layer.addSublayer(bottomFade)
    guide.isAccessibilityElement = false
    guide.backgroundColor = .clear
    view.addSubview(guide)
    guideOutline.fillColor = UIColor.clear.cgColor
    guideOutline.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
    guideOutline.lineWidth = 1
    guideCorners.fillColor = UIColor.clear.cgColor
    guideCorners.strokeColor = UIColor.white.withAlphaComponent(0.92).cgColor
    guideCorners.lineWidth = 2
    guideCorners.lineCap = .round
    guideCorners.lineJoin = .round
    view.layer.addSublayer(guideOutline)
    view.layer.addSublayer(guideCorners)
    focusRing.layer.borderWidth = 1
    focusRing.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
    focusRing.layer.cornerRadius = 26
    focusRing.isUserInteractionEnabled = false
    focusRing.isHidden = true
    focusRing.alpha = 0
    view.addSubview(focusRing)

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.accessibilityLabel = strings["close"]
    closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
    torchButton.accessibilityLabel = strings["torchOn"]
    torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
    titleLabel.text = strings["title"]
    titleLabel.textAlignment = .center
    titleLabel.font = .preferredFont(forTextStyle: .subheadline)
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.minimumScaleFactor = 0.75
    headerBar.addArrangedSubview(closeButton)
    headerBar.addArrangedSubview(titleLabel)
    headerBar.addArrangedSubview(torchButton)
    headerBar.spacing = 10
    headerBar.alignment = .center
    for button in [closeButton, torchButton] {
      button.tintColor = .white
      button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
      button.layer.cornerRadius = 18
      button.layer.cornerCurve = .continuous
      let width = button.widthAnchor.constraint(equalToConstant: 44)
      width.priority = .defaultHigh
      width.isActive = true
      button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    headerBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBar)

    instruction.font = .preferredFont(forTextStyle: .callout)
    detail.font = .preferredFont(forTextStyle: .caption1)
    sheetTitle.font = .preferredFont(forTextStyle: .headline)
    sheetBody.font = .preferredFont(forTextStyle: .subheadline)
    vinLabel.font = .monospacedSystemFont(ofSize: 22, weight: .semibold)
    vinLabel.adjustsFontSizeToFitWidth = true
    vinLabel.minimumScaleFactor = 0.55
    for label in [titleLabel, instruction, detail, sheetTitle, sheetBody, vinLabel] {
      label.textColor = .white
      label.adjustsFontForContentSizeCategory = true
      label.textAlignment = .center
    }
    titleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
    detail.textColor = UIColor.white.withAlphaComponent(0.78)
    sheetBody.textColor = UIColor.white.withAlphaComponent(0.8)
    instruction.numberOfLines = 2
    detail.numberOfLines = 2
    sheetTitle.numberOfLines = 0
    sheetBody.numberOfLines = 0
    spinner.color = .white
    stillSpinner.color = .white
    stillSpinner.hidesWhenStopped = true
    var still = UIButton.Configuration.plain()
    still.image = UIImage(systemName: "camera.viewfinder")
    still.imagePadding = 6
    still.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 14)
    still.baseForegroundColor = .white
    still.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = UIFont.preferredFont(forTextStyle: .footnote)
      return outgoing
    }
    stillButton.configuration = still
    stillButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
    stillButton.layer.cornerRadius = 16
    stillButton.layer.cornerCurve = .continuous
    stillButton.clipsToBounds = true
    stillButton.addTarget(self, action: #selector(requestStill), for: .touchUpInside)
    stillButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
    primary.addTarget(self, action: #selector(primaryAction), for: .touchUpInside)
    secondary.addTarget(self, action: #selector(scanAgain), for: .touchUpInside)
    primary.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    secondary.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
    for button in [primary, secondary] {
      button.titleLabel?.adjustsFontForContentSizeCategory = true
      button.titleLabel?.numberOfLines = 0
      button.titleLabel?.textAlignment = .center
      button.layer.cornerRadius = 14
      button.layer.cornerCurve = .continuous
    }
    primary.backgroundColor = .white
    primary.setTitleColor(.black, for: .normal)
    primary.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    secondary.backgroundColor = UIColor.white.withAlphaComponent(0.1)
    secondary.setTitleColor(.white, for: .normal)
    secondary.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

    liveChrome.axis = .vertical
    liveChrome.alignment = .center
    liveChrome.spacing = 6
    liveChrome.translatesAutoresizingMaskIntoConstraints = false
    liveChrome.addArrangedSubview(instruction)
    liveChrome.addArrangedSubview(detail)
    let stillRow = UIStackView(arrangedSubviews: [stillSpinner, stillButton])
    stillRow.spacing = 8
    stillRow.alignment = .center
    liveChrome.addArrangedSubview(stillRow)
    view.addSubview(liveChrome)

    let sheetContent = UIStackView(arrangedSubviews: [spinner, sheetTitle, sheetBody, vinLabel, primary, secondary])
    sheetContent.axis = .vertical
    sheetContent.spacing = 12
    sheetContent.translatesAutoresizingMaskIntoConstraints = false
    sheet.layer.cornerRadius = 20
    sheet.layer.cornerCurve = .continuous
    sheet.clipsToBounds = true
    sheet.translatesAutoresizingMaskIntoConstraints = false
    sheet.contentView.addSubview(sheetContent)
    view.addSubview(sheet)
    NSLayoutConstraint.activate([
      headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
      headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      liveChrome.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      liveChrome.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      liveChrome.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      sheet.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      sheetContent.leadingAnchor.constraint(equalTo: sheet.contentView.leadingAnchor, constant: 18),
      sheetContent.trailingAnchor.constraint(equalTo: sheet.contentView.trailingAnchor, constant: -18),
      sheetContent.topAnchor.constraint(equalTo: sheet.contentView.topAnchor, constant: 18),
      sheetContent.bottomAnchor.constraint(equalTo: sheet.contentView.bottomAnchor, constant: -18),
    ])
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleFocusTap))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
    let notifications = NotificationCenter.default
    notifications.addObserver(self, selector: #selector(resignActive), name: UIApplication.willResignActiveNotification, object: nil)
    notifications.addObserver(self, selector: #selector(becomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    notifications.addObserver(self, selector: #selector(cameraFailed), name: .AVCaptureSessionRuntimeError, object: session)
    notifications.addObserver(self, selector: #selector(cameraFailed), name: .AVCaptureSessionWasInterrupted, object: session)
    notifications.addObserver(self, selector: #selector(subjectAreaChanged), name: .AVCaptureDeviceSubjectAreaDidChange, object: nil)
    render(.initializing)
  }

  override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); authorize() }
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if !finished { finish(nil) }
  }
  deinit { NotificationCenter.default.removeObserver(self) }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    preview.frame = view.bounds
    topFade.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 140)
    bottomFade.frame = CGRect(x: 0, y: view.bounds.height - 180, width: view.bounds.width, height: 180)
    let frame = VinGuideLayout.logicalFrame(in: view.bounds)
    guide.frame = frame
    updateGuideChrome(frame)
    // Capture and preview are both portrait, 720×1280, with aspect-fill preview.
    let scale = max(view.bounds.width / 720, view.bounds.height / 1280)
    let imageWidth = 720 * scale, imageHeight = 1280 * scale
    let x = (frame.minX + (imageWidth - view.bounds.width) / 2) / imageWidth
    let y = (frame.minY + (imageHeight - view.bounds.height) / 2) / imageHeight
    let region = CGRect(x: x, y: 1 - y - frame.height / imageHeight,
                        width: frame.width / imageWidth, height: frame.height / imageHeight)
    let clipped = region.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    captureQueue.async {
      self.primaryRoi = clipped
      self.expandedRoi = VinRoi.expanded(clipped)
    }
  }

  private func updateGuideChrome(_ frame: CGRect) {
    guideOutline.path = UIBezierPath(roundedRect: frame, cornerRadius: 6).cgPath
    let path = UIBezierPath()
    let arm: CGFloat = 18
    let corners: [(CGPoint, CGFloat, CGFloat)] = [
      (CGPoint(x: frame.minX, y: frame.minY), arm, arm),
      (CGPoint(x: frame.maxX, y: frame.minY), -arm, arm),
      (CGPoint(x: frame.minX, y: frame.maxY), arm, -arm),
      (CGPoint(x: frame.maxX, y: frame.maxY), -arm, -arm),
    ]
    for (origin, dx, dy) in corners {
      path.move(to: CGPoint(x: origin.x + dx, y: origin.y))
      path.addLine(to: origin)
      path.addLine(to: CGPoint(x: origin.x, y: origin.y + dy))
    }
    guideCorners.path = path.cgPath
  }

  private func authorize() {
    guard !finished, !requestingPermission, UIApplication.shared.applicationState == .active else { return }
    if case .confirmation = state { return }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: startCamera()
    case .notDetermined:
      requestingPermission = true
      AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
        DispatchQueue.main.async {
          guard let self = self, !self.finished else { return }
          self.requestingPermission = false
          if allowed { self.authorize() } else { self.render(.denied) }
        }
      }
    default: render(.denied)
    }
  }

  private func startCamera() {
    render(.initializing)
    captureQueue.async {
      guard !self.terminated else { return }
      do {
        if !self.configured {
          guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                self.session.canSetSessionPreset(.hd1280x720) else { throw ScannerError.unavailable }
          try self.configure(device)
          let input = try AVCaptureDeviceInput(device: device)
          self.session.beginConfiguration()
          self.session.sessionPreset = .hd1280x720
          guard self.session.canAddInput(input), self.session.canAddOutput(self.output) else {
            self.session.commitConfiguration()
            throw ScannerError.unavailable
          }
          self.session.addInput(input)
          self.session.addOutput(self.output)
          self.output.alwaysDiscardsLateVideoFrames = true
          self.output.setSampleBufferDelegate(self, queue: self.captureQueue)
          self.output.connection(with: .video)?.videoOrientation = .portrait
          self.session.commitConfiguration()
          self.device = device
          self.configured = true
        }
        self.stability.reset()
        self.schedule.reset()
        self.lastAnalysis = 0
        self.analyzing = false
        self.stillRequested = false
        self.latestPixelBuffer = nil
        self.lastHint = .defaultHint
        self.recognitionEnabled = true
        if !self.session.isRunning { self.session.startRunning() }
        guard self.session.isRunning else { throw ScannerError.unavailable }
        DispatchQueue.main.async {
          guard !self.finished, UIApplication.shared.applicationState == .active else { return }
          self.preview.connection?.videoOrientation = .portrait
          self.torchButton.isEnabled = self.device?.hasTorch == true
          self.render(.scanning)
          self.applyFocus(at: self.guide.center, locked: false)
        }
      } catch { DispatchQueue.main.async { self.render(.unavailable) } }
    }
  }

  private func configure(_ device: AVCaptureDevice) throws {
    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }
    if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
    if device.isSmoothAutoFocusSupported { device.isSmoothAutoFocusEnabled = true }
    if device.isAutoFocusRangeRestrictionSupported { device.autoFocusRangeRestriction = .near }
    if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
    if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
      device.whiteBalanceMode = .continuousAutoWhiteBalance
    }
    device.isSubjectAreaChangeMonitoringEnabled = true
    if device.isLowLightBoostSupported { device.automaticallyEnablesLowLightBoostWhenAvailable = true }
    let minZ = device.minAvailableVideoZoomFactor
    let maxZ = Swift.min(device.maxAvailableVideoZoomFactor, device.activeFormat.videoMaxZoomFactor)
    device.videoZoomFactor = VinCameraZoom.factor(minimum: minZ, maximum: maxZ)
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard recognitionEnabled, !terminated else { return }
    if let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) { latestPixelBuffer = buffer }
    if stillRequested {
      stillRequested = false
      guard let buffer = latestPixelBuffer else {
        DispatchQueue.main.async { self.finishStill(vin: nil) }
        return
      }
      analyzing = true
      let vin = recognize(buffer: buffer, pass: .still)
      analyzing = false
      DispatchQueue.main.async { self.finishStill(vin: vin) }
      return
    }
    let now = ProcessInfo.processInfo.systemUptime
    guard !analyzing, now - lastAnalysis >= 0.4, let buffer = latestPixelBuffer else { return }
    lastAnalysis = now
    analyzing = true
    let pass = schedule.nextLive()
    if let vin = recognize(buffer: buffer, pass: pass) {
      recognitionEnabled = false
      analyzing = false
      stopCapture()
      DispatchQueue.main.async {
        guard !self.finished, UIApplication.shared.applicationState == .active else { return }
        self.render(.confirmation(vin))
      }
      return
    }
    schedule.markUnsuccessful()
    analyzing = false
    publishHint()
  }

  /// Frames stay in-memory. Vision orientation matches the portrait sample buffer (`.up`).
  private func recognize(buffer: CVPixelBuffer, pass: VinScanPass) -> String? {
    let roi = pass == .primary ? primaryRoi : expandedRoi
    let confidence: Float = pass == .still ? 0.35 : 0.5
    let text = VNRecognizeTextRequest()
    text.recognitionLevel = .accurate
    text.usesLanguageCorrection = false
    text.recognitionLanguages = ["en-US"] // VIN alphabet; not a UI language.
    text.regionOfInterest = roi
    let barcodes = VNDetectBarcodesRequest()
    barcodes.regionOfInterest = roi
    let supported = (try? barcodes.supportedSymbologies()) ?? VinBarcode.preferred
    barcodes.symbologies = VinBarcode.enabled(from: supported)
    do {
      let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up)
      try? handler.perform([barcodes])
      try handler.perform([text])
      let observations = text.results ?? []
      let payloads = (barcodes.results ?? []).compactMap(\.payloadStringValue)
      let primarySpans = VinOcrSpans.from(observations, top: 1, minConfidence: confidence)
      let primary = VinCandidates.extract(spans: primarySpans)
        .union(VinCandidates.extract(payloads))
      var candidates = primary
      if candidates.isEmpty {
        let altSpans = VinOcrSpans.from(observations, top: 3, minConfidence: confidence)
        candidates = VinOcrDecision.resolve(
          primary: primary,
          fallback: VinCandidates.extract(spans: altSpans)
        )
      }
      if candidates.isEmpty &&
        (pass == .still || VinFallbackSchedule.shouldEnhance(unsuccessful: schedule.unsuccessful))
      {
        if let extra = recognizeFallbackImages(buffer: buffer, roi: roi, confidence: confidence) {
          candidates = extra
        }
      }
      if pass == .still { return VinStillResult.accept(candidates) }
      return stability.observe(candidates)
    } catch {
      if pass == .still { return nil }
      recognitionEnabled = false
      captureQueue.async { self.stopCapture() }
      DispatchQueue.main.async { self.render(.unavailable) }
      return nil
    }
  }

  /// Memory-only ROI variants. Barcode is not re-run on transformed images.
  private func recognizeFallbackImages(
    buffer: CVPixelBuffer,
    roi: CGRect,
    confidence: Float
  ) -> Set<String>? {
    autoreleasepool {
      let source = CIImage(cvPixelBuffer: buffer)
      let crop = VinFallbackCrop.pixelRect(roi: roi, imageExtent: source.extent)
      guard crop.width >= 8, crop.height >= 8 else { return nil }
      let cropped = source.cropped(to: crop)
      let scale = VinFallbackScale.factor
      let variants = [
        cropped.transformed(by: CGAffineTransform(scaleX: scale, y: scale)),
        VinFallbackRender.mildContrastGray(cropped),
      ]
      for variant in variants {
        guard let cgImage = VinFallbackContext.ci.createCGImage(variant, from: variant.extent) else {
          continue
        }
        if let found = ocrFallback(cgImage: cgImage, confidence: confidence), !found.isEmpty {
          return found
        }
      }
      return nil
    }
  }

  private func ocrFallback(cgImage: CGImage, confidence: Float) -> Set<String>? {
    let text = VNRecognizeTextRequest()
    text.recognitionLevel = .accurate
    text.usesLanguageCorrection = false
    text.recognitionLanguages = ["en-US"]
    do {
      try VNImageRequestHandler(cgImage: cgImage, orientation: .up).perform([text])
      let spans = VinOcrSpans.from(text.results ?? [], top: 3, minConfidence: confidence)
      let candidates = VinCandidates.extract(spans: spans)
      return candidates.isEmpty ? nil : candidates
    } catch {
      return nil
    }
  }

  private func publishHint() {
    let next = VinHintSchedule.kind(unsuccessful: schedule.unsuccessful)
    guard next != lastHint else { return }
    lastHint = next
    DispatchQueue.main.async {
      guard case .scanning = self.state else { return }
      let text = self.hintCopy(next)
      UIView.transition(with: self.detail, duration: 0.2, options: .transitionCrossDissolve) {
        self.detail.text = text
      }
    }
  }

  private func hintCopy(_ kind: VinHintKind) -> String {
    switch kind {
    case .defaultHint: return strings["hint"] ?? ""
    case .closer:
      return copy("closerHint", ru: "Поднесите камеру ближе или измените угол",
                  ro: "Apropiați camera sau schimbați unghiul")
    case .glare:
      return copy("glareHint", ru: "Избегайте бликов на стекле",
                  ro: "Evitați reflexiile de pe sticlă")
    }
  }

  private func copy(_ key: String, ru: String, ro: String) -> String {
    if let value = strings[key], !value.isEmpty { return value }
    let language = Locale.preferredLanguages.first ?? "ru"
    return language.hasPrefix("ro") ? ro : ru
  }

  // Must run on captureQueue. Frames are never serialized, saved, or uploaded.
  private func stopCapture() {
    recognitionEnabled = false
    stillRequested = false
    latestPixelBuffer = nil
    if let device = device, device.hasTorch, (try? device.lockForConfiguration()) != nil {
      device.torchMode = .off
      device.unlockForConfiguration()
    }
    if session.isRunning { session.stopRunning() }
    DispatchQueue.main.async {
      self.torchEnabled = false
      self.updateTorchControl()
    }
  }

  private func render(_ next: State) {
    guard !finished else { return }
    let previous = state
    state = next
    preview.isHidden = true
    guide.isHidden = true
    guideOutline.isHidden = true
    guideCorners.isHidden = true
    topFade.isHidden = true
    bottomFade.isHidden = true
    liveChrome.isHidden = true
    sheet.isHidden = true
    torchButton.isHidden = true
    spinner.stopAnimating()
    spinner.isHidden = true
    stillSpinner.stopAnimating()
    stillButton.isEnabled = true
    primary.isHidden = true
    secondary.isHidden = true
    vinLabel.isHidden = true
    vinLabel.text = nil
    sheetTitle.text = nil
    sheetBody.text = nil
    detail.text = strings["hint"]
    switch next {
    case .initializing:
      sheet.isHidden = false
      sheetTitle.text = strings["initializing"]
      spinner.isHidden = false
      spinner.startAnimating()
    case .scanning:
      instruction.text = strings["instruction"]
      let stillTitle = copy("recognizeFrame", ru: "Распознать кадр", ro: "Recunoaște cadrul")
      var still = stillButton.configuration
      still?.title = stillTitle
      stillButton.configuration = still
      stillButton.accessibilityLabel = stillTitle
      preview.isHidden = false
      guide.isHidden = false
      guideOutline.isHidden = false
      guideCorners.isHidden = false
      topFade.isHidden = false
      bottomFade.isHidden = false
      liveChrome.isHidden = false
      torchButton.isHidden = !torchButton.isEnabled
    case .confirmation(let vin):
      preview.isHidden = false
      topFade.isHidden = false
      bottomFade.isHidden = false
      sheet.isHidden = false
      sheetTitle.text = strings["found"]
      vinLabel.isHidden = false
      vinLabel.attributedText = NSAttributedString(
        string: vin,
        attributes: [
          .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .semibold),
          .foregroundColor: UIColor.white,
          .kern: 1.1,
        ]
      )
      vinLabel.accessibilityLabel = vin.map(String.init).joined(separator: " ")
      primary.setTitle(strings["use"], for: .normal)
      secondary.setTitle(strings["again"], for: .normal)
      primary.isHidden = false
      secondary.isHidden = false
    case .denied:
      sheet.isHidden = false
      sheetTitle.text = strings["deniedTitle"]
      sheetBody.text = strings["denied"]
      primary.setTitle(strings["settings"], for: .normal)
      primary.isHidden = false
    case .unavailable:
      sheet.isHidden = false
      sheetTitle.text = strings["unavailableTitle"]
      sheetBody.text = strings["unavailable"]
      primary.setTitle(strings["retry"], for: .normal)
      primary.isHidden = false
    }
    sheetTitle.isHidden = (sheetTitle.text ?? "").isEmpty
    sheetBody.isHidden = (sheetBody.text ?? "").isEmpty
    if !isSameSurface(previous, next) {
      let focus: UIView = liveChrome.isHidden ? sheetTitle : instruction
      UIAccessibility.post(notification: .screenChanged, argument: focus)
    }
  }

  private func isSameSurface(_ lhs: State, _ rhs: State) -> Bool {
    switch (lhs, rhs) {
    case (.scanning, .scanning), (.initializing, .initializing),
         (.denied, .denied), (.unavailable, .unavailable):
      return true
    case (.confirmation, .confirmation):
      return true
    default:
      return false
    }
  }

  @objc private func primaryAction() {
    switch state {
    case .confirmation(let vin): finish(vin)
    case .denied:
      if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    case .unavailable: authorize()
    default: break
    }
  }

  @objc private func requestStill() {
    guard case .scanning = state else { return }
    stillButton.isEnabled = false
    stillSpinner.startAnimating()
    captureQueue.async { self.stillRequested = true }
  }

  private func finishStill(vin: String?) {
    stillSpinner.stopAnimating()
    stillButton.isEnabled = true
    guard case .scanning = state else { return }
    if let vin {
      captureQueue.async { self.stopCapture() }
      render(.confirmation(vin))
    }
  }

  @objc private func scanAgain() { render(.initializing); authorize() }
  @objc private func cancel() { finish(nil) }
  override func accessibilityPerformEscape() -> Bool { cancel(); return true }

  private func finish(_ vin: String?) {
    guard !finished else { return }
    finished = true
    preview.isHidden = true
    captureQueue.async {
      self.terminated = true
      self.stopCapture()
      self.output.setSampleBufferDelegate(nil, queue: nil)
      // Release camera ownership before returning to Flutter or reopening it.
      DispatchQueue.main.async {
        self.onFinish?(vin)
        self.onFinish = nil
      }
    }
  }

  @objc private func resignActive() {
    preview.isHidden = true
    captureQueue.async {
      self.stopCapture()
      self.stability.reset()
      self.schedule.reset()
    }
  }
  @objc private func becomeActive() { authorize() }
  @objc private func cameraFailed() {
    DispatchQueue.main.async {
      self.captureQueue.async { self.stopCapture() }
      self.render(.unavailable)
    }
  }

  @objc private func handleFocusTap(_ gesture: UITapGestureRecognizer) {
    guard case .scanning = state else { return }
    let point = gesture.location(in: view)
    if headerBar.frame.contains(point) || liveChrome.frame.contains(point) || sheet.frame.contains(point) { return }
    if view.hitTest(point, with: nil) is UIControl { return }
    showFocusRing(at: point)
    applyFocus(at: point, locked: true)
    focusResume?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self, case .scanning = self.state else { return }
      self.applyFocus(at: self.guide.center, locked: false)
    }
    focusResume = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: work)
  }

  @objc private func subjectAreaChanged() {
    DispatchQueue.main.async {
      guard case .scanning = self.state else { return }
      self.applyFocus(at: self.guide.center, locked: false)
    }
  }

  private func applyFocus(at layerPoint: CGPoint, locked: Bool) {
    guard preview != nil else { return }
    let devicePoint = preview.captureDevicePointConverted(fromLayerPoint: layerPoint)
    captureQueue.async {
      guard let device = self.device, (try? device.lockForConfiguration()) != nil else { return }
      defer { device.unlockForConfiguration() }
      if device.isFocusPointOfInterestSupported {
        device.focusPointOfInterest = devicePoint
        let mode: AVCaptureDevice.FocusMode = locked ? .autoFocus : .continuousAutoFocus
        if device.isFocusModeSupported(mode) { device.focusMode = mode }
      }
      if device.isExposurePointOfInterestSupported {
        device.exposurePointOfInterest = devicePoint
        let mode: AVCaptureDevice.ExposureMode = locked ? .autoExpose : .continuousAutoExposure
        if device.isExposureModeSupported(mode) { device.exposureMode = mode }
      }
    }
  }

  private func showFocusRing(at point: CGPoint) {
    focusRing.bounds = CGRect(x: 0, y: 0, width: 52, height: 52)
    focusRing.center = point
    focusRing.isHidden = false
    focusRing.alpha = 0
    focusRing.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
    UIView.animate(withDuration: 0.1, animations: {
      self.focusRing.alpha = 1
      self.focusRing.transform = .identity
    }, completion: { _ in
      UIView.animate(withDuration: 0.22, delay: 0.28, options: .curveEaseOut, animations: {
        self.focusRing.alpha = 0
      }, completion: { _ in
        self.focusRing.isHidden = true
      })
    })
  }

  @objc private func toggleTorch() {
    let enabled = !torchEnabled
    captureQueue.async {
      guard self.recognitionEnabled, let device = self.device, device.hasTorch else { return }
      do {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        if enabled { try device.setTorchModeOn(level: min(0.5, AVCaptureDevice.maxAvailableTorchLevel)) }
        else { device.torchMode = .off }
        DispatchQueue.main.async { self.torchEnabled = enabled; self.updateTorchControl() }
      } catch { DispatchQueue.main.async { self.torchButton.isEnabled = false } }
    }
  }
  private func updateTorchControl() {
    torchButton.setImage(UIImage(systemName: torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill"), for: .normal)
    torchButton.tintColor = torchEnabled ? UIColor.white : UIColor.white.withAlphaComponent(0.92)
    torchButton.backgroundColor = UIColor.white.withAlphaComponent(torchEnabled ? 0.22 : 0.12)
    torchButton.accessibilityLabel = strings[torchEnabled ? "torchOff" : "torchOn"]
  }
  private enum ScannerError: Error { case unavailable }
}
