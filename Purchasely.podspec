#
# Be sure to run `pod lib lint Purchasely.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Purchasely'
  s.version          = '2.7.2'
  s.summary          = 'The simplest way to add In App Purchase to your apps.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Purchasely is the simplest and quickest way to add In App Purchases and Subscriptions within your app. No more struggling with all the steps, receipt validation, rejection, …
Purchasely handles everything from product presentation to app receipt validation.
4 lines of code and you are good to go.
                       DESC

  s.homepage         = 'https://www.purchasely.io'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Copyright', :text => 'Copyright 2020 Purchasely SAS' }
  s.author           = { 'jfgrang' => 'jfgrang@2appaz.com' }
  s.source           = { :git => 'https://github.com/Purchasely/Purchasely-iOS.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/PurchaselyCom'

  s.swift_versions = ['5.0', '5.1', '5.2', '5.3']
  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.vendored_frameworks = ['Purchasely/Frameworks/Purchasely.xcframework']

  s.ios.frameworks = 'UIKit', 'StoreKit'
  s.tvos.frameworks = 'UIKit', 'TVUIKit', 'StoreKit'

  s.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
end
