THCache
===

[![Build Status](https://travis-ci.org/hons82/THCache.png)](https://travis-ci.org/hons82/THCache)
[![Pod Version](http://img.shields.io/cocoapods/v/THCache.svg?style=flat)](http://cocoadocs.org/docsets/THCache/)
[![Pod Platform](http://img.shields.io/cocoapods/p/THCache.svg?style=flat)](http://cocoadocs.org/docsets/THCache/)
[![Pod License](http://img.shields.io/cocoapods/l/THCache.svg?style=flat)](http://opensource.org/licenses/MIT)
[![Coverage Status](https://coveralls.io/repos/hons82/THCache/badge.svg)](https://coveralls.io/r/hons82/THCache)

These are some helper classes to handle storing and retrieving of standard data structures

# Installation

### CocoaPods

Install with [CocoaPods](http://cocoapods.org) by adding the following to your Podfile:

``` ruby
platform :ios, '6.1'
pod 'THCache', '~> 0.9.1'
```

**Note**: We follow http://semver.org for versioning the public API.

### Manually

Or copy the `THCache/` directory from this repo into your project.

# Usage

With NSString
```Objective-C
- (void)StringStorage {
    [THCacher storeItemsToCache:@"ItemToStore" withKey:@"testStringStorageKey"];
    NSString *itemToStore = [THCacher restoreItemsFromCacheWithKey:@"testStringStorageKey"]];
    
    NSError *err;
    [THCacher removeItemsFromCacheWithKey:@"testStringStorageKey"error:&err]
}
```
With NSArray
```Objective-C
- (void)NSArrayStorage {
    NSArray *array = @[@"ItemToStore", @"ItemToStore"];
    [array storeArrayToCacheWithKey:@"testNSArrayStorageKey"];
    array2 = [[NSArray alloc] initArrayFromCacheWithKey:@"testNSArrayStorageKey"];
    
    NSError *err;
    [array removeArrayFromCacheWithKey:@"testNSArrayStorageKey"error:&err];
}
```
With NSData
```Objective-C
- (void)NSDataStorage {
    NSData *data = [@"ItemToStore" dataUsingEncoding:NSUTF8StringEncoding];
    [data storeDataToCacheWithKey:@"testNSDataStorageKey"];
    [data initDataFromCacheWithKey:@"testNSDataStorageKey"];
    
    NSError *err;
    [data removeDataFromCacheWithKey:@"testNSDataStorageKey"error:&err];
}
```
With NSDictionary
```Objective-C
- (void)testNSDictionaryStorage {
    
    NSDictionary *dictionary = @{@"Key1" : @"ItemToStore", @"Key2" : @"ItemToStore"};
    [dictionary storeDictionaryToCacheWithKey:@"testNSDictionaryStorageKey"];
    NSDictionary *dictionary2 = [[NSDictionary alloc] initDictionaryFromCacheWithKey:@"testNSDictionaryStorageKey"];
    
    NSError *err;
    [dictionary removeDictionaryFromCacheWithKey:@"testNSDictionaryStorageKey"error:&err];
}
```



#Contributions

...are really welcome.

# License

Source code of this project is available under the standard MIT license. Please see [the license file](LICENSE.md).


