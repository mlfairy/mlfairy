Pod::Spec.new do |s|
	s.name         = "MLFairy"
	s.version      = "0.0.1"
	s.summary      = "Better understand your CoreML models"
	s.homepage     = "https://www.mlfairy.com"
	s.license      = { :type => "GPLv3", :file => "License.txt" }
	s.author       = { "MLFairy" => "support@mlfairy.com" }
	s.source       = { :git => "https://github.com/mlfairy/ios.git", :tag => s.version }
	s.requires_arc = true
	s.swift_version = "5.0"

	s.ios.deployment_target = "11.0"
	s.tvos.deployment_target = "11.0"
	s.osx.deployment_target = "10.13"

	s.default_subspec = "Core"
	s.subspec "Core" do |ss|
		ss.source_files  = "MLFairy/Source"
		ss.dependency "Alamofire", "~> 5.0.0-rc.2"
		ss.dependency "PromisesSwift", "~> 1.2.8"
		ss.frameworks  = "Foundation", "Security"
	end
end
  
