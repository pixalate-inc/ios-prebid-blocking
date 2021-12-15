Pixalate Pre-Bid Fraud Blocking SDK for iOS
===

The Pixalate Pre-Bid Blocking SDK gives easy access to Pixalate's pre-bid fraud blocking APIs.

## Installation & Integration

### CocoaPods

The latest version of the pre-built SDK is available on [CocoaPods](http://example.com/XXXXXXX__PLACEHOLDER), and can be integrated by adding the following line into your project's `Podfile`:

```gradle
pod 'pixalate-prebid-blocking'
```

Then run `pod install` to download the latest version of the SDK.

### Integrating Into an Objective-C Project

To access the SDK, import `PXBlocking/PXBlocking.h` into your source code.

## Authentication & Configuration

To use the Pixalate Blocking SDK, you must first configure it using `[PXBlocking setGlobalConfig:]`. The simplest way to create a configuration is to use the provided builder:

```objc
PXGlobalConfig *pxConfig = [PXGlobalConfig makeWithApiKey:@"<your api key>" builder:^(PXGlobalConfigBuilder *builder) {
  builder.threshold = 0.75; // set the fraud probability threshold, above which ads will be blocked. A value in the range 0.75 - 0.9 is recommended.
  builder.timeoutInterval = 3; // set the max amount of time to wait before aborting a blocking request in seconds.
  builder.ttl = 60 * 60 * 8; // set the TTL of the response cache in seconds, or set to 0 to disable the cache.
  builder.strategy = [[PXDefaultBlockingStrategy alloc] init]; // set the strategy to use to retrieve blocking parameters from the device.
}];

[PXBlocking setGlobalConfig:pxConfig];
```

Only the API Key is required; all other parameters are optional, and provide reasonable defaults.

Parameter Name   | Description | Default Value
-----------------|-------------|-------------:
apiKey           | Your developer API key, required to access Pixalate API services. | --
threshold        | The probability threshold at which blocking should occur.<br/>Normal range is anywhere from 0.75-0.9. | 0.75
ttl              | How long results should be cached before making another request. | 8 hours
timeoutInterval  | How long requests are allowed to run before aborting. In the rare case of a network issue, this will help ensure the Pixalate SDK is not a bottleneck to running your ads. | 2 seconds
blockingStrategy | The blocking strategy used to retrieve device parameters such as device ID and IPv4 address. | PXDefaultBlockingStrategy

---
**Note:** The timeout interval is shared across the strategy and the blocking request itself. For example, if the timeout interval is 2 seconds, and the strategy takes 0.2 seconds to execute, the blocking request will have 1.8 seconds remaining to execute. Ensure the timeout interval is long enough to compensate for both.

---

### Blocking Strategies

Pixalate provides some default behavior for collecting both the device ID and IPv4 address of the host device for blocking purposes.

#### Device ID

Returns the value of `[[[UIDevice currentDevice] identifierForVendor] UUIDString]`.

#### IPv4 Address

The SDK will retrieve the external IPv4 address of the device by utilizing a Pixalate service.

#### IPv6 Address

The pre-bid fraud API will support IPv6 soon, and default support for IPv6 will be integrated into the SDK at that time. Currently, the default strategy returns `nil` for IPv6.

#### User Agent

Although the pre-bid fraud API supports passing browser user agents, the concept of a user agent is nebulous when in an app context. For this reason, the default blocking strategy does not utilize user agents, and returns `nil`.

#### Caching

By default, the blocking strategy will inherity the TTL and timeout interval of the global configuration. This value can be overridden by creating a new PXDefaultBlockingStrategy instance and passing it to the PXBlockingConfigBuilder:

```objc
builder.strategy = [[PXDefaultBlockingStrategy alloc] initWithTTL:60 * 5]; // sets the blocking strategy TTL to 5 minutes
```

### Custom Blocking Strategies

If the default behavior is not working for your use case, you would like more control over how you retrieve the blocking parameters, or if you want to add or remove included parameters, you can create your own blocking strategy.

PXBlockingStrategyProtocol provides no TTL or timeout behaviors by default. This provides full flexibility over alternative methods of retrieval and caching of values. 

Below is a contrived example of how to go about implementing such a strategy. As it only implements getIPv4 and returns null for the other methods, IPv4 is the only parameter that will be included in requests.

```objc
#import <PXBlocking/PXBlocking.h>

@interface MyCustomBlockingStrategy : NSObject <PXBlockingStrategyProtocol>

@end

@implementation MyCustomBlockingStrategy

- (void) getIPv4Address:(PXBlockingStrategyResultHandler)resultHandler {
  dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
    // Retrieve the IPv4 address async...
    
    // call the handler with the resulting value
    resultHandler(@"my-ip4-value", nil);

    // if an error is caught, pass it as the second argument:
    resultHandler(nil, myError);
  });
}

@end
```

If you'd like to modify the default strategy, such as adding or removing a parameter, you can create a subclass of `PXDefaultBlockingStrategy`. `PXDefaultBlockingStrategy` uses a slightly different API to allow easy subclassing without losing TTL and timeout behavior. To take advantage of this, override the `-Impl` version of the various methods instead of the originals. For example, `getIPv4Address` becomes `getIPv4AddressImpl`. The rest of the signature stays unchanged.

```objc
@interface MyCustomBlockingStrategy : PXDefaultBlockingStrategy

@end

@implementation MyCustomBlockingStrategy

- (void) getIPv4AddressImpl:(PXBlockingStrategyResultHandler)resultHandler {
  resultHandler(nil,nil); // disable the sending of IPv4 addresses
}

- (void) getUserAgentImpl:(PXBlockingStrategyResultHandler)resultHandler {
  resultHandler(@"some-user-agent-string",nil); // add behavior not present in the default strategy
}

@end
```

Regardless of whether you create your own strategy or extend the default strategy, you can then pass your new strategy into the config builder:

```objc
builder.strategy = [[MyCustomBlockingStrategy alloc] init];
```

---
**NOTE:** Default caching behavior for blocking parameters is implemented in  `DefaultBlockingStrategy`. If you implement your own blocking strategy using `BlockingStrategy`, you will need to manage your own caching of parameters. Blocking request caching and TTL is always managed by the SDK, and is unaffected by the blocking strategy.

---

## Blocking Ads

Once the SDK is set up, you can implement it into your ad loading logic. The SDK is ad framework agnostic, and can easily integrate into whatever workflow your project requires.

The basic pattern for performing a block request is as follows:

```objc
[PXBlocking requestBlockStatus:^(bool block, NSError *error) {
  if( error != nil ) {
    // An error occurred while executing the request. In this case, `block` will always be false.
  }

  if( block ) {
    // Traffic is above the blocking threshold and should be blocked.
  } else {
    // Traffic is below the threshold and can be allowed.
    // You can load your ads here.
  }
}];
```

### Testing Responses

During development, it may be helpful to test both blocked and unblocked behavior. You can accomplish this using the alternate method `[PXBlocking requestBlockStatusWithBlockingMode:handler:]. You can then pass `PXBlockingModeDefault` to use normal behavior, `PXBlockingModeAlwaysBlock` to simulate a blocked response, or `PXBlockingModeNeverBlock` to simulate a non-blocked response:

```objc
[PXBlocking requestBlockStatusWithBlockingMode:PXBlockingModeAlwaysBlock handler:^(bool block, NSError *error) {
  // ...
}];
```

These debug responses will still execute the blocking strategy, and so can be used to test custom blocking strategies as well.

### Logging

The SDK supports multiple logging levels which can provide additional context when debugging. The current level can be set through `[PXBlocking setLogLevel:]`, and defaults to `PXLogLevelInfo`. Logging can be disabled entirely by setting the level to `PXLogLevelNone`.

```objc
[PXBlocking setLogLevel:PXLogLevelDebug];
```