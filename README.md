MoPub iOS Plugin for Gideros
=======================

Installation
------------
1. Add `mopub.mm` to your XCode project
2. Download latest MoPub SDK on [GitHub](https://github.com/mopub/mopub-client)
3. Add MoPubiOS/MoPubSDK folder and MoPubiOs/TouchJSON folder to your XCode project
4. Add frameworks: AdSupport (set it to optional)

Usage
-----
After plugin installation, look at example project

Final Note
----------
If you want to support AdMob, iAd, or Millenial Media network, add their respective adapter from MoPub SDK to XCode. See this [tutorial](http://help.mopub.com/customer/portal/articles/285180-ios-integration-part-iii-iad-millennial-admob-and-custom-networks)

To support custom event you must look at `mopub.mm` and then search `// EXAMPLE OF CUSTOM EVENT`. Below those line is example of custom event dispatcher. See more about custom event [here](http://help.mopub.com/customer/portal/articles/285180-ios-integration-part-iii-iad-millennial-admob-and-custom-networks)

This plugin has been tested on Gideros 2012.09.6 exported Xcode project and XCode 4.5.2

The lua API is compatible with [MoPub Android Plugin for Gideros](https://github.com/zaniar/gideros_mopub)
