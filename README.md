Pixalate Pre-Bid Fraud Blocking SDK for iOS
===

The Pixalate Pre-Bid Blocking SDK gives easy access to Pixalate's pre-bid fraud blocking APIs.


## Installation & Integration

### CocoaPods

The latest version of the pre-built SDK is available on [CocoaPods](https://cocoapods.org/pods/pixalate-prebid-blocking), and can be integrated by adding `pod 'pixalate-prebid-blocking'` into your project's Podfile.

Then run `pod install` to download the latest version of the SDK.

```ruby
pod 'pixalate-prebid-blocking'
```

### Integrating Into an Objective-C Project

To access the SDK, import `PXBlocking/PXBlocking.h` into your source code.


## Authentication & Basic Configuration

To use the Pixalate Blocking SDK, you must first configure it using `[PXBlocking setGlobalConfig:]`.

Only the API Key is required. All other parameters are optional, and provide reasonable defaults.

```objc
// import the main library header
#import <pixalate_prebid_blocking/PXBlocking.h>

// Place this in your app initialization code.
// A sample configuration & initialization -- the values chosen for this example
// are not meaningful.
PXGlobalConfig *pxConfig = [PXGlobalConfig makeWithApiKey:@"<your api key>" builder:^(PXGlobalConfigBuilder *builder) {
  builder.threshold = 0.8;
  builder.timeoutInterval = 3; 
  builder.ttl = 60 * 60 * 8; 
  builder.strategy = [[PXDefaultBlockingStrategy alloc] init]; // set the strategy to use to retrieve blocking parameters from the device.
}];

[PXBlocking setGlobalConfig:pxConfig];
```

Parameter Name   | Description | Default Value
-----------------|-------------|-------------:
apiKey           | Your developer API key, required to access Pixalate API services. | --
threshold        | The probability threshold at which blocking should occur.<br/>Normal range is anywhere from 0.75-0.9. | 0.75
ttl              | How long results should be cached before making another request. | 8 hours
timeoutInterval  | How long requests are allowed to run before aborting. In the rare case of a network issue, this will help ensure the Pixalate SDK is not a bottleneck to running your ads. | 2 seconds
blockingStrategy | The blocking strategy used to retrieve device parameters such as device ID and IPv4 address. | `PXDefaultBlockingStrategy`


## Blocking Ads

Once the SDK is set up, you can implement it into your ad loading logic. The SDK is ad framework agnostic, and can easily integrate into whatever workflow your project requires.

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

During development, it may be helpful to test both blocked and unblocked behavior. You can accomplish this using the alternate method `[PXBlocking requestBlockStatusWithBlockingMode:handler:]. You can then pass `PXBlockingModeDefault` to use normal behavior, `PXBlockingModeAlwaysBlock` to simulate a blocked response, or `PXBlockingModeNeverBlock` to simulate a non-blocked response.

```objc
[PXBlocking requestBlockStatusWithBlockingMode:PXBlockingModeAlwaysBlock handler:^(bool block, NSError *error) {
  /* ... */
}];
```

These debug responses will still execute the blocking strategy, and so can be used to test custom blocking strategies as well.

## Logging

The SDK supports multiple logging levels which can provide additional context when debugging. The level can be set by calling `[PXBlocking setLogLevel:]`, and defaults to `PXLogLevelInfo`. Logging can be disabled entirely by setting the level to `PXLogLevelNone`.

```objc
[PXBlocking setLogLevel:PXLogLevelDebug];
```

## Advanced Configuration

### Default Strategy Behavior

Pixalate provides default strategies for both the device ID and IPv4 address parameters. These values should cover most common use cases.

If for any reason you wish to add, remove, or modify the blocking strategies used by the library, you can create a custom strategy. This is explained in more detail below.

#### Device ID

Returns the value of `[[[UIDevice currentDevice] identifierForVendor] UUIDString]`.

#### IPv4 Address

The SDK will retrieve the external IPv4 address of the device by utilizing a Pixalate service.

#### User Agent

Although the pre-bid fraud API supports passing browser user agents, the concept of a user agent is nebulous when in an app context. For this reason, the default blocking strategy does not utilize user agents.

#### Parameter Caching

```objc
// In your initialization code
PXGlobalConfig *pxConfig = [PXGlobalConfig makeWithApiKey:@"<your api key>" builder:^(PXGlobalConfigBuilder *builder) {
  /* ... */
  // set the blocking strategy TTL to 5 minutes
  builder.strategy = [[PXDefaultBlockingStrategy alloc] initWithTTL:60 * 5];
}];
```

By default, the blocking strategy will inherit the TTL and timeout interval of the global configuration. This value can be overridden by creating a new PXDefaultBlockingStrategy instance and passing it to the PXBlockingConfigBuilder when you initialize the library.

### Custom Blocking Strategies

#### Extending PXDefaultBlockingStategy

```objc
// ExtendedBlockingStrategy.h
@interface ExtendedBlockingStrategy : PXDefaultBlockingStrategy

@end

// ExtendedBlockingStrategy.m
@implementation ExtendedBlockingStrategy

- (void) getIPv4Address:(PXBlockingStrategyResultHandler)resultHandler {
  resultHandler(nil,nil); // disable the sending of IPv4 addresses
}

- (void) getUserAgent:(PXBlockingStrategyResultHandler)resultHandler {
  NSString *userAgent = /* Retrieve the user agent somehow */;
  resultHandler(userAgent,nil); // add behavior not present in the default strategy
}

@end
```

If you'd like to modify the default strategy, such as adding or removing a parameter, you can create a subclass of `PXDefaultBlockingStrategy`. `PXDefaultBlockingStrategy` uses a slightly different API to allow easy subclassing without losing TTL and timeout behavior. To take advantage of this, override the `-Impl` version of the various methods instead of the originals. For example, `getIPv4Address` becomes `getIPv4AddressImpl`. The rest of the signature stays unchanged.

#### Creating a Strategy From Scratch

```objc
// A contrived example of how to go about implementing such a strategy. 
// As it only implements getIPv4 and returns null for the other methods, 
// IPv4 is the only parameter that will be included in requests.
#import <pixalate_prebid_blocking/PXBlocking.h>

// MyCustomBlockingStrategy.h
@interface MyCustomBlockingStrategy : NSObject <PXBlockingStrategyProtocol>

@end

// MyCustomBlockingStrategy.m
@implementation MyCustomBlockingStrategy

- (void) getIPv4Address:(PXBlockingStrategyResultHandler)resultHandler {
  NSString *ipv4 = /* Retrieve the IPv4 address... */;
  
  // call the handler with the resulting value
  resultHandler(@"my-ip4-value", nil);

  // if an error is caught, pass it as the second argument:
  resultHandler(nil, myError);
}

- (void) getDeviceID:(PXBlockingStrategyResultHandler)resultHandler {
  resultHandler(nil,nil);
}

- (void) getUserAgent:(PXBlockingStrategyResultHandler)resultHandler {
  resultHandler(nil,nil);
}

@end
```

```objc
// Then, in your initialization code, pass your modified strategy
// into the builder
PXGlobalConfig *pxConfig = [PXGlobalConfig makeWithApiKey:@"<your api key>" builder:^(PXGlobalConfigBuilder *builder) {
  /* ... */
  // set the blocking strategy TTL to 5 minutes
  builder.strategy = [[MyCustomBlockingStrategy alloc] init];
}];
```

If you have an alternate use case that the default strategies do not cover, you can create your own blocking strategy.

`PXBlockingStrategyProtocol` provides no TTL or timeout behaviors by default. This provides full flexibility over alternative methods of retrieval and caching of values.