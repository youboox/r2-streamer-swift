Pod::Spec.new do |s|

  s.name         = "R2Streamer"
  s.version      = "1.2.5"
  s.license      = "BSD 3-Clause License"
  s.summary      = "R2 Streamer"
  s.homepage     = "http://readium.github.io"
  s.author       = { "Aferdita Muriqi" => "aferdita.muriqi@gmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/youboox/r2-streamer-swift.git", :branch => "YoubooxVersion02" }
  s.exclude_files = ["**/Info*.plist","**/Carthage/*"]
  s.source_files  = ["r2-streamer-swift/**/*.{m,h,swift}"]
  s.resources    = ['r2-streamer-swift/Resources/**/*.{otf,js}', 'r2-streamer-swift/Resources/styles/**']
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.swift_version  = "5.0"

  s.libraries =  ['z', 'xml2']

  s.dependency 'R2Shared',      '~> 1.4.1'
  s.dependency 'Fuzi',          '3.1.1'
  s.dependency 'CryptoSwift',   '~> 1.4.0'
  s.dependency 'GCDWebServer',  '3.5.2'
  s.dependency 'Minizip'

end
