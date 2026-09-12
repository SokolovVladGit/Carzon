import CoreImage
import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  private let vin = "WVWZZZ1JZXW000001"

  func testValidVINAndNormalization() {
    XCTAssertEqual(VinCandidates.normalize(" wvw-zzz1jz xw000001 "), vin)
    XCTAssertEqual(VinCandidates.extract([vin]), [vin])
  }

  func testDocumentAndSpacedVIN() {
    XCTAssertEqual(VinCandidates.extract(["VIN: \(vin); year: 1999"]), [vin])
    XCTAssertEqual(VinCandidates.extract(["W V W Z Z Z 1 J Z X W 0 0 0 0 0 1"]), [vin])
  }

  func testRejectInvalidLengthAndForbiddenCharacters() {
    for invalid in [String(vin.dropLast()), vin + "1", "WVWZZZ1JZXW00000I", "WVWZZZ1JZXW00000O", "WVWZZZ1JZXW00000Q"] {
      XCTAssertTrue(VinCandidates.extract([invalid]).isEmpty)
      XCTAssertFalse(VinCandidates.isValid(invalid))
    }
    XCTAssertFalse(VinCandidates.isValid(vin + "\n"))
  }

  func testBarcodePayloads() {
    XCTAssertTrue(VinCandidates.extract(["https://example.com", "123456", "HELLO"]).isEmpty)
    XCTAssertEqual(VinCandidates.extract(["VIN:\(vin)"]), [vin])
    XCTAssertEqual(VinCandidates.extract([vin.lowercased()]), [vin])
  }

  func testUnrelatedObservationsAreNotJoined() {
    XCTAssertTrue(VinCandidates.extract(["WVWZZZ1JZ", "XW000001"]).isEmpty)
  }

  func testNearbySameLineFragmentsJoinIntoVIN() {
    let left = VinTextSpan(text: "WVWZZZ1JZ", box: CGRect(x: 0.10, y: 0.45, width: 0.28, height: 0.06))
    let right = VinTextSpan(text: "XW000001", box: CGRect(x: 0.40, y: 0.45, width: 0.24, height: 0.06))
    XCTAssertEqual(VinCandidates.extract(spans: [left, right]), [vin])
  }

  func testDistantFragmentsAreNotJoined() {
    let top = VinTextSpan(text: "WVWZZZ1JZ", box: CGRect(x: 0.10, y: 0.70, width: 0.28, height: 0.06))
    let bottom = VinTextSpan(text: "XW000001", box: CGRect(x: 0.10, y: 0.20, width: 0.24, height: 0.06))
    XCTAssertTrue(VinCandidates.extract(spans: [top, bottom]).isEmpty)
  }

  func testFormattedIdentifiersAreNotTruncatedIntoVINs() {
    let spaced = vin.map(String.init).joined(separator: " ")
    XCTAssertTrue(VinCandidates.extract([spaced + " 2"]).isEmpty)
    XCTAssertTrue(VinCandidates.extract(["2 " + spaced]).isEmpty)
    XCTAssertTrue(VinCandidates.extract([spaced + " O"]).isEmpty)
    XCTAssertEqual(VinCandidates.extract(["VIN: WVW-ZZZ1JZ-XW000001; YEAR: 1999"]), [vin])
  }

  func testTwoMatchingSuitableAnalysesConfirm() {
    var stability = VinStability()
    XCTAssertNil(stability.observe([vin]))
    XCTAssertEqual(stability.observe([vin]), vin)
    stability.reset()
    XCTAssertNil(stability.observe([vin]))
  }

  func testStabilityConfirmsTwoOfThreeWithUnsuitableGap() {
    var stability = VinStability()
    XCTAssertNil(stability.observe([vin]))
    XCTAssertNil(stability.observe([]))
    XCTAssertNil(stability.observe([vin, "1HGBH41JXMN109186"]))
    XCTAssertEqual(stability.observe([vin]), vin)
  }

  func testCompetingCandidatesDoNotConfirm() {
    let other = "1HGBH41JXMN109186"
    var stability = VinStability()
    XCTAssertNil(stability.observe([vin]))
    XCTAssertNil(stability.observe([other]))
    XCTAssertNil(stability.observe([vin]))
    XCTAssertNil(stability.observe([other]))
    XCTAssertNil(stability.observe([other]))
    XCTAssertEqual(stability.observe([other]), other)
  }

  func testRoiFallbackAfterRepeatedFailures() {
    var schedule = VinScanSchedule()
    XCTAssertEqual(schedule.nextLive(), .primary)
    XCTAssertEqual(schedule.nextLive(), .primary)
    schedule.markUnsuccessful()
    schedule.markUnsuccessful()
    schedule.markUnsuccessful()
    XCTAssertEqual(schedule.nextLive(), .primary)
    XCTAssertEqual(schedule.nextLive(), .expanded)
  }

  func testExpandedRoiStaysInsideUnitSquare() {
    let primary = CGRect(x: 0.05, y: 0.40, width: 0.90, height: 0.20)
    let expanded = VinRoi.expanded(primary)
    XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(expanded))
    XCTAssertGreaterThan(expanded.height, primary.height)
    XCTAssertGreaterThanOrEqual(expanded.width, primary.width)
  }

  func testHintScheduleRotatesAfterFailures() {
    XCTAssertEqual(VinHintSchedule.kind(unsuccessful: 0), .defaultHint)
    XCTAssertEqual(VinHintSchedule.kind(unsuccessful: 8), .closer)
    XCTAssertEqual(VinHintSchedule.kind(unsuccessful: 16), .glare)
    XCTAssertEqual(VinHintSchedule.kind(unsuccessful: 24), .closer)
  }

  func testBarcodePreferredSymbologiesAreConservative() {
    XCTAssertEqual(
      VinBarcode.enabled(from: VinBarcode.preferred + [.ean13, .upce]),
      VinBarcode.preferred
    )
    XCTAssertTrue(VinCandidates.extract(["https://example.com", "123456"]).isEmpty)
  }

  func testStillPassAcceptsSingleValidCandidateOnly() {
    XCTAssertEqual(VinStillResult.accept([vin]), vin)
    XCTAssertNil(VinStillResult.accept([]))
    XCTAssertNil(VinStillResult.accept([vin, "1HGBH41JXMN109186"]))
    XCTAssertNil(VinStillResult.accept(["WVWZZZ1JZXW00000O"]))
  }

  func testDefaultZoomIsModestAndClamped() {
    XCTAssertEqual(VinCameraZoom.factor(minimum: 1, maximum: 8), 1.35)
    XCTAssertEqual(VinCameraZoom.factor(minimum: 1.5, maximum: 8), 1.5)
    XCTAssertEqual(VinCameraZoom.factor(minimum: 1, maximum: 1.2), 1.2)
  }

  func testLogicalGuideFrameKeepsStage6ABounds() {
    let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
    let frame = VinGuideLayout.logicalFrame(in: bounds)
    XCTAssertEqual(frame.origin.x, 24)
    XCTAssertEqual(frame.origin.y, 844 * 0.31, accuracy: 0.001)
    XCTAssertEqual(frame.width, 342)
    XCTAssertEqual(frame.height, 100)
    XCTAssertEqual(
      frame,
      CGRect(x: 24, y: bounds.height * 0.31, width: max(1, bounds.width - 48), height: 100)
    )
  }

  func testPresenterUsesDirectRootController() {
    let root = UIViewController()
    let window = makeWindow(root: root)
    XCTAssertEqual(VinScannerPresenter.host(preferred: nil, windows: [window]), root)
    XCTAssertEqual(VinScannerPresenter.host(preferred: root, windows: []), root)
  }

  func testPresenterUsesPresentedController() {
    let root = UIViewController()
    let presented = UIViewController()
    let window = makeWindow(root: root)
    let shown = expectation(description: "presented")
    root.present(presented, animated: false) { shown.fulfill() }
    wait(for: [shown], timeout: 1)
    XCTAssertEqual(VinScannerPresenter.top(from: root), presented)
    XCTAssertEqual(VinScannerPresenter.host(preferred: root, windows: [window]), presented)
  }

  func testPresenterUsesNavigationVisibleController() {
    let visible = UIViewController()
    let navigation = UINavigationController(rootViewController: visible)
    XCTAssertEqual(VinScannerPresenter.top(from: navigation), visible)
  }

  func testPresenterUsesSelectedTabController() {
    let selected = UIViewController()
    let tabs = UITabBarController()
    tabs.viewControllers = [UIViewController(), selected]
    tabs.selectedIndex = 1
    XCTAssertEqual(VinScannerPresenter.top(from: tabs), selected)
  }

  func testPresenterWalksNestedContainersAndPresentation() {
    let leaf = UIViewController()
    let navigation = UINavigationController(rootViewController: leaf)
    let tabs = UITabBarController()
    tabs.viewControllers = [navigation]
    let window = makeWindow(root: tabs)
    let presented = UIViewController()
    let shown = expectation(description: "nested presented")
    leaf.present(presented, animated: false) { shown.fulfill() }
    wait(for: [shown], timeout: 1)
    XCTAssertEqual(VinScannerPresenter.top(from: tabs), presented)
    XCTAssertEqual(VinScannerPresenter.host(preferred: nil, windows: [window]), presented)
  }

  func testPresenterReturnsNilWithoutUsableWindow() {
    XCTAssertNil(VinScannerPresenter.host(preferred: nil, windows: []))
    XCTAssertNil(VinScannerPresenter.host(preferred: UIViewController(), windows: []))
    let hidden = makeWindow(root: UIViewController())
    hidden.isHidden = true
    XCTAssertNil(VinScannerPresenter.host(preferred: nil, windows: [hidden]))
  }

  func testPrimaryValidCandidateWinsImmediately() {
    XCTAssertEqual(VinOcrDecision.resolve(primary: [vin], fallback: ["1HGBH41JXMN109186"]), [vin])
    XCTAssertEqual(
      VinFallbackChain.firstNonEmpty([[vin], ["1HGBH41JXMN109186"]]),
      [vin]
    )
  }

  func testFallbackUsesSecondVisionAlternativeWhenPrimaryEmpty() {
    let alt = VinCandidates.extract(["WVWZZZ1JZXW00000O", vin, "GARBAGE"])
    XCTAssertEqual(alt, [vin])
    XCTAssertEqual(VinOcrDecision.resolve(primary: [], fallback: alt), [vin])
  }

  func testInvalidOcrAlternativesAreIgnored() {
    let fallback = VinCandidates.extract(["HELLO", "123456", "WVWZZZ1JZXW00000I"])
    XCTAssertTrue(fallback.isEmpty)
    XCTAssertTrue(VinOcrDecision.resolve(primary: [], fallback: fallback).isEmpty)
  }

  func testFallbackDoesNotInventO0Substitution() {
    XCTAssertTrue(VinCandidates.extract(["WVWZZZ1JZXW00000O"]).isEmpty)
    XCTAssertTrue(VinCandidates.isValid(vin))
    XCTAssertFalse(VinCandidates.isValid("WVWZZZ1JZXW00000O"))
    XCTAssertTrue(
      VinOcrDecision.resolve(
        primary: [],
        fallback: VinCandidates.extract(["WVWZZZ1JZXW00000O"])
      ).isEmpty
    )
  }

  func testEnhancedPassDoesNotRunOnEveryPrimaryFrame() {
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: 0))
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: 5))
    XCTAssertTrue(VinFallbackSchedule.shouldEnhance(unsuccessful: 6))
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: 7))
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: 8))
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: 9))
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: 10))
    XCTAssertTrue(VinFallbackSchedule.shouldEnhance(unsuccessful: 11))
    XCTAssertTrue(VinFallbackSchedule.shouldEnhance(unsuccessful: 16))
    var schedule = VinScanSchedule()
    XCTAssertEqual(schedule.nextLive(), .primary)
    XCTAssertFalse(VinFallbackSchedule.shouldEnhance(unsuccessful: schedule.unsuccessful))
  }

  func testFallbackScaleIsModestAndCropStaysInsideExtent() {
    XCTAssertEqual(VinFallbackScale.factor, 1.45, accuracy: 0.001)
    XCTAssertGreaterThan(VinFallbackScale.factor, 1.2)
    XCTAssertLessThan(VinFallbackScale.factor, 1.7)
    let extent = CGRect(x: 0, y: 0, width: 1000, height: 500)
    let roi = CGRect(x: 0.10, y: 0.20, width: 0.50, height: 0.40)
    let crop = VinFallbackCrop.pixelRect(roi: roi, imageExtent: extent)
    XCTAssertTrue(extent.contains(crop))
    XCTAssertEqual(crop.origin.x, 100, accuracy: 1)
    XCTAssertEqual(crop.origin.y, 100, accuracy: 1)
    XCTAssertEqual(crop.width, 500, accuracy: 1)
    XCTAssertEqual(crop.height, 200, accuracy: 1)
  }

  func testContrastGrayKeepsExtentAndDoesNotInventVIN() {
    let color = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 32, height: 16))
    let rendered = VinFallbackRender.mildContrastGray(color)
    XCTAssertEqual(rendered.extent.width, 32, accuracy: 0.5)
    XCTAssertEqual(rendered.extent.height, 16, accuracy: 0.5)
    XCTAssertTrue(VinCandidates.extract(["OIQ", "WVWZZZ1JZXW00000O"]).isEmpty)
  }

  func testFallbackSuccessShortCircuitsRemainingBatches() {
    XCTAssertEqual(VinFallbackChain.firstNonEmpty([[], [vin], ["1HGBH41JXMN109186"]]), [vin])
    XCTAssertTrue(VinFallbackChain.firstNonEmpty([[], []]).isEmpty)
  }

  func testFallbackCandidateUsesSameStabilityAccumulator() {
    var stability = VinStability()
    let first = VinOcrDecision.resolve(primary: [], fallback: [vin])
    let second = VinOcrDecision.resolve(primary: [], fallback: [vin])
    XCTAssertNil(stability.observe(first))
    XCTAssertEqual(stability.observe(second), vin)
  }

  func testStillEnhancedFallbackStillRequiresSingleValidVIN() {
    XCTAssertEqual(VinStillResult.accept(VinFallbackChain.firstNonEmpty([[], [vin]])), vin)
    XCTAssertNil(VinStillResult.accept(VinFallbackChain.firstNonEmpty([[], [vin, "1HGBH41JXMN109186"]])))
    XCTAssertNil(
      VinStillResult.accept(
        VinFallbackChain.firstNonEmpty([VinCandidates.extract(["WVWZZZ1JZXW00000O"])])
      )
    )
  }

  func testPresenterFallsBackWhenPreferredIsDetached() {
    let detached = UIViewController()
    let root = UIViewController()
    let window = makeWindow(root: root)
    XCTAssertEqual(VinScannerPresenter.host(preferred: detached, windows: [window]), root)
  }

  private func makeWindow(root: UIViewController) -> UIWindow {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
    window.rootViewController = root
    window.makeKeyAndVisible()
    return window
  }

}
