<p align="center"><img height="160" src="logo.png" /></p>

# MLFairy

[![codebeat badge](https://codebeat.co/badges/55c8d36b-cde6-4cf3-bbd1-573c61662900)](https://codebeat.co/projects/github-com-mlfairy-mlfairy-master) 
![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20watchOS%20%7C%20macOS%20%7C%20tvOS-cc9c00.svg)


MLFairy gives developers the tools needed to better understand their CoreML models. It gives them the ability to update and deploy their latest CoreML model. MLFairy also gives you the ability to collect predictions from your model, so you can improve your model based on real-world results from your app.

## Installation

MLFairy only supports Swift Package Manager, add the following to your Package.swift 

```
.package(name: "MLFairy", url: "https://github.com/mlfairy/mlfairy.git", from: "0.0.3"),
```

Or add the following URL when adding the dependencies in Xcode through `File > Swift Packages > Add Package Dependencies`

```
https://github.com/mlfairy/mlfairy.git
```

## Usage

### Downloading the latest CoreML model

After installing MLFairy, you can access an API like this:

```swift
private let TOKEN = "<get your token from your account at www.mlfairy.com>"
let model = <Generated Class from .mlmodel file>()
MLFairy.getCoreMLModel(TOKEN) { response in
	switch (response.result) {
		case .success(let model):
			guard let model = model else {
				print("Failed to get CoreML model.")
				return
			}
			// Assign the returned model to your existing model
			// If you want to collect predictions, you can assign your model to response.mlFairyModel
			model.model = model
		case .failure(let error):
			print("Failed to get CoreML model \(String(describing: error)).")
	}
}
```
### Automatically collect predictions

You can collect your model's predictions using MLFairy. You can do this with `MLFairy.wrapCoreMLModel`.

```swift
private let TOKEN = "<get your token from your account at www.mlfairy.com>"
let model = <Generated Class from .mlmodel file>()
model.model = MLFairy.wrapCoreMLModel(model.model, token: TOKEN)
```

> **Note**: `MLFairy.getCoreMLModel` also returns an optional wrapped model if you are using MLFairy for model distribution.
## License

MLFairy is released under an GPL-3 license. See [License.txt](License.txt) for more information.
