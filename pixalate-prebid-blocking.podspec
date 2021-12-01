#
# Be sure to run `pod lib lint prebid-blocking.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'pixalate-prebid-blocking'
  s.version          = '0.1.0'
  s.summary          = "Block high-IVT probable impressions in your mobile apps by utilizing Pixalate's Pre-Bid Blocking API."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Pixalate/prebid-blocking'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'LGPL', :file => 'LICENSE' }
  s.author           = { 'Pixalate' => 'nate@pixalate.com' }
  s.source           = { :git => 'https://github.com/Pixalate/prebid-blocking.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/pixalate'

  s.ios.deployment_target = '9.0'

  s.source_files = 'prebid-blocking/Classes/**/*'
  
  # s.resource_bundles = {
  #   'prebid-blocking' => ['prebid-blocking/Assets/*.png']
  # }

  s.public_header_files = 'Pod/Classes/*.h'
  s.private_header_files = 'Pos/Classes/Private/*.h'
   s.frameworks = 'Foundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
