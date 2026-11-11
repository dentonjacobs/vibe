# Vibe

> **Note:** This is a personal fork, updated to build with Xcode 27 / Swift 5+ and run on macOS 26. It isn't an official release.
> Vibe was created by [Thomas Schoffelen](https://github.com/tschoffelen), who deserves all credit for the app. This fork was made from [kraigparkinson/vibe](https://github.com/kraigparkinson/vibe).

A tiny tool that allows you to see how you're doing with your [OmniFocus](https://www.omnigroup.com/omnifocus/) tasks.

It retrieves the completed dates of all your OmniFocus tasks, and shows you the number of completed tasks over the last 7 days, per month and per weekday. Feel free to extend it with more interesting stats, and if you use it and like it, I would love to [hear from you](https://twitter.com/tschoffelen).

**[Download the latest version here](https://github.com/tschoffelen/vibe/releases)**

## Building

Requirements: macOS 26 or later, Xcode 27, and OmniFocus.

From the command line:

```sh
xcodebuild -project Vibe.xcodeproj -scheme Vibe -configuration Release -derivedDataPath build clean build
```

The app is built to `build/Build/Products/Release/Vibe.app`. To install it, quit any running copy of Vibe and copy the app into `/Applications`:

```sh
ditto build/Build/Products/Release/Vibe.app /Applications/Vibe.app
```

Or in Xcode: open `Vibe.xcodeproj`, choose **Product › Archive**, then **Distribute App › Copy App**, and drag the exported `Vibe.app` into `/Applications`.

### First launch

- The first time Vibe runs, macOS asks whether Vibe may control OmniFocus. Click **Allow**. Vibe reads only the completion dates of your tasks.
- The app is signed to run locally, so macOS may treat each rebuild as a new app. If Vibe shows "Couldn't read OmniFocus" after a rebuild, reset the permission and relaunch:

  ```sh
  tccutil reset AppleEvents com.dntn.vibe
  ```

- To start Vibe at login, add it in **System Settings › General › Login Items**.


![Screenshot](screenshot.png)


### Send me a coffee
Like my work? [Consider giving a small donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=X8Y8GRHBU7V8N). 