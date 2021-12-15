#
# Be sure to run `pod lib lint prebid-blocking.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'pixalate-prebid-blocking'
  s.version          = '0.1.0'
  s.summary          = "Block high IVT in your mobile apps by utilizing Pixalate's Pre-Bid Blocking API."

  s.homepage         = 'https://github.com/pixalate-inc/ios-prebid-blocking'
  s.license          = { :type => 'LGPL', :file => 'LICENSE' }
  s.author           = { 'Pixalate' => 'support@pixalate.com' }
  s.source           = { :git => 'https://github.com/pixalate-inc/ios-prebid-blocking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'pixalate-prebid-blocking/**/*'
  
  s.public_header_files = 'pixalate-prebid-blocking/*.h'
  s.private_header_files = 'pixalate-prebid-blocking/Private/*.h'
  s.frameworks = 'Foundation'
end
