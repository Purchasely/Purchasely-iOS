//
//  PLYLottieBridge.swift
//  Purchasely
//
//  Created by Jean-François GRANG on 03/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import Lottie

@objc(PLYLottieBridge)
class PLYLottieBridge: NSObject {

	var animationView: LottieAnimationView?

	override init() {
		super.init()
	}

	@objc class func bridge(with animationURL: URL) -> PLYLottieBridge? {
		let result = PLYLottieBridge()
		result.animationView = LottieAnimationView(url: animationURL, closure: { _ in
			result.animationView?.play()
		}, animationCache: nil)
		result.animationView?.loopMode = .loop
		return result
	}

	@objc func view() -> UIView? {
		return animationView
	}

	@objc func loop(_ loop: Bool) {
		animationView?.loopMode = loop ? .loop : .playOnce
	}

	@objc func fill(_ fill: Bool) {
		animationView?.contentMode = fill ? .scaleAspectFill : .scaleAspectFit
	}

	@objc func play() {
		animationView?.play{ (finished) in
		}
	}

	@objc func pause() {
		animationView?.pause()
	}

	@objc func stop() {
		animationView?.stop()
	}
}
