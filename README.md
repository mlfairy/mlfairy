<p align="center">
  <img height="160" src="logo.png" />
</p>

# MLFairy

[![Build Status](https://travis-ci.com/mlfairy/ios.svg?branch=master)](https://travis-ci.com/mlfairy/ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/MLFairy.svg)](https://cocoapods.org/pods/MLFairy)

MLFairy gives developers the tools needed to better understand their CoreML models. It gives them the ability to update and deploy their latest CoreML model.

## Installation

### Cocoapods

For MLFairy, use the following entry in your Podfile:

```
pod 'MLFairy' '~> 0.0.1'
```

Then run `pod install`.

In any file you'd like to use MLFairy in, don't forget to import the framework with `import MLFairy`.

### Carthage

Make the following entry in your Cartfile:

```
github "mlfairy/mlfairy" ~> 0.0.1
```

Then run `carthage update`.

If this is your first time using Carthage in the project, you'll need to go through some additional steps as explained over [at Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

## Usage

After installing MLFairy, you can access an API like this:

```swift
private let TOKEN = "<get your token from your account at www.mlfairy.com>"

let model = <Generated Class from .mlmodel file>()

MLFairy.getCoreMLModel(TOKEN) { model, error in
	guard error == nil else {
		print("Failed to get CoreML model \(String(describing: error)).")
		return
	}

	guard let _ = model else {
		print("Failed to get CoreML model.")
		return
	}

	print("Model Downloaded")
	ml.model = model // Assign the returned model to your existing model
}
```

## License

MLFairy is released under an MIT license. See [License.txt](License.txt) for more information.