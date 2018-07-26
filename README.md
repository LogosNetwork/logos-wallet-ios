# Logos Light Wallet
An iOS light wallet for the Logos cryptocurrency, written purely in Swift.

## Features
* send and receive Nano
* change representative
* multiple account address support
* client-side address book
* QR generation and scanning
* biometrics
* export seed to encrypted zip (note: the baked-in macOS unzip utility won't unzip it)
* in-app block viewer
* multiple languages including English, Japanese, French, German, Spanish, and Swedish. [Contribute here.](https://poeditor.com/join/project/jmtLv86PbQ)

## Running the project
The project should build to a device out-of-the-box. However, if you wish to run on sim, you'll have to create a new `Sodium.framework` build [off of my swift-sodium fork](https://github.com/nebyark/swift-sodium) that includes sim architectures. 
