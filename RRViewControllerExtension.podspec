#
#  Be sure to run `pod spec lint RRViewControllerExtension.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "RRViewControllerExtension"
  s.version      = "3.3.0"
  s.summary      = "UINavigationBar appearance management, memory leak detection, convenient UIViewController property and methods."
  
  #说明:注释掉下面两项配置，在用 XCode15.0.1编译的时候，无法通过pod提交验证；并报错 "error: Cannot code sign because the target does not have an Info.plist file and one is not being generated automatically. "
  #但是！如果加上这两项配置，在打包后提交到App Store又会出现验证错误："The bundle 'xxx/RRViewControllerExtension.framework' is missing plist key. The Info.plist file is missing the required key: CFBundleShortVersionString. "
  #解决方法是取消这两项配置，然后把 1、代码下载到本地，将pod改成本地引用，2、或者将pod源指向github
#  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'GENERATE_INFOPLIST_FILE' => 'NO' }
#  s.user_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'GENERATE_INFOPLIST_FILE' => 'NO' }


  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
A lightweight UIViewController category extension for UINavigationBar appearance management, view controller push/pop/dismiss management, memory leak detection and other convenient property and methods.
                   DESC

  s.homepage     = "https://github.com/Roen-Ro/RRViewControllerExtension"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = "MIT"

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "罗亮富(Roen)" => "zxllf23@163.com" }
 # s.social_media_url   = "https://twitter.com/RoenLuo"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  s.platform     = :ios, '13.0'

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/Roen-Ro/RRViewControllerExtension.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "RRViewControllerExtension/**/*.{h,m}"
  # s.exclude_files = "Classes/Exclude"

  s.public_header_files = "RRViewControllerExtension/*.h"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  #  s.resource_bundles = {
  #        'RRViewControllerExtension' => ['RRViewControllerExtension/resources/*.png']
  #    }
  # s.resource  = "RRViewControllerExtension/resources/**/*"
  # s.resources = "RRViewControllerExtension/resources/*.png"
  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  s.framework  = "UIKit"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true


end
