Pod::Spec.new do |s|
	s.name         = "MLFairy"
	s.version      = "%VERSION%"
	s.summary      = "Better understand your CoreML models"
	s.homepage     = "https://github.com/MLFairy/ios"
	s.license      = { :type => "GPLv3", :file => "License.txt" }
	s.author             = { "MLFairy" => "support@mlfairy.com" }
	s.ios.deployment_target = '11.0'
	s.osx.deployment_target = '10.13'
	s.tvos.deployment_target = '11.0'
	s.source       = { :git => "https://github.com/MLFairy/ios.git", :tag => s.version }
	s.default_subspec = "Core"
	s.swift_version = '5.0'
	s.cocoapods_version = '>= 1.4.0'  
  
	s.subspec "Core" do |ss|
	  ss.source_files  = "MLFairy/Source/"
	  ss.dependency "Alamofire", "~> 5.0.0-rc.2"
	  ss.dependency "PromisesSwift", "~> 1.2.8"
	  ss.frameworks  = "Foundation", "Security"
	end
  end
  
