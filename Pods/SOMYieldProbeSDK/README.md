# SevenOne Media YieldProbe SDK

In order to enable YieldProbe Header Bidding for display ads you must integrate SevenOne Media's YieldProbe SDK.

Once initialized, the SDK polls bids from YieldProbe servers which you should then consume by adding them as custom targeting to the display ad requests. If yield of a YieldProbe bid is higher than of a direct-sold inventory, the ad server will deliver the Yieldlab ad associated with the bid. This might lead to improved display ad revenue in your app.

## Installation via CocoaPods

Please install the SOM YieldProbe SDK directly with CocoaPods.

```
target 'YourApp' do
    pod 'SOMYieldProbeSDK', git: 'https://github.com/SevenOneMedia/adtec-app-ios-yieldprobe.git', tag: '1.0.0'
end
```

### Integration in Your App

The following part contains instructions on how to integrate the YieldProbe SDK into your app.

### Initialization

The SDK must be imported on each controller you want to use it.

```
import SOMYieldProbeSDK 
```

On each app start, the SDK must be initialized with the ad slots you want to request bids for (banner, rectancle or interstitial). For each ad slot, its id and type must be specified.

#### Option 1 - Json string
You can pass the required ad slot information to the SDK directly as JSON from the ad config. In order to do that, you must extract the JSON part of the ad contig which is stored under **Ad Config** > **displayAd** > **yieldProbe**. Then, you must pass the JSON string to the SDK.

```
let ypSlots = "..." // Extracted ad slot information as JSON string from the ad config. 
SOMYieldProbe.initialize(ypSlots, npa: yourNpaSetting) // NPA=true/false
```

#### Option 2 - Dictionary
However, you can also pass the ad slot ids and types as Discionary. For each slot, the dictionary must contain the slot id as integer key and as the slot type as string value.

```
let ypSlots = [12345: "type1", ..., 67890: "typeN"] // Structure of the dictionary
SOMYieldProbe.initialize(ypSlots, npa: yourNpaSetting) // npa=true/false
```

#### GDPR / Non-Persolalized Ads

Regarding the GDPR, the parameter NPA can be passed to the SDK enabling the user to force non-personalized ads. In general, you must define a global toggle in your app allowing the user to opt out from persolalized ads (npa=true) or to opt in (npa=false). If this value is not passed to the SDK, it assumes that the user has opted in for personalized ads (npa=false).

If the NPA state changes while the app is in use (the user changes the NPA toggle), the SDK must be informed. Therefore you must use the following method.

```
SOMYieldProbe.setNpa(yourNpaSetting) // npa=true/false
```

### Update

You must update the YieldProbe SDK on every page load and page reload to refresh the bids for each ad slot.

```
SOMYieldProbe.update() // Request new bid for each slot if expired.
```

### Retrieve and consume YieldProbe targeting

Before requesting a display ad using the Google Ads SDK, you have to retrieve the YieldProbe bid for the specific slot. A slot is identified by its YieldProbe id. The SDK will return an Dictionary which must be added to the custom targeting property of the DFPRequest ad request associated with the ad slot/view. Afterwards make the ad request.

```
let customTargeting = ... // Existing custom targeting e.g. NuggAd.
let ypTargeting = SOMYieldProbe.getTargeting(slotId: yourYPSlotId) // Is empty if no bid is available for this slot.
// Add YieldProbe targeting to custom targeting.
for (k, v) in ypTargeting {
    targeting[k] = v
}
// Perform Ad request with Google Ads SDK.
let request = DFPRequest()
request.customTargeting = customTargeting
let yourBanner = DFPBannerView(adSize: yourAdSize)
yourBanner.adUnitID = yourAdUnitID
yourBanner.load(request)
```