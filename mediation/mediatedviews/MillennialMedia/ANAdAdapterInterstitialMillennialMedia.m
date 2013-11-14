/*   Copyright 2013 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "ANAdAdapterInterstitialMillennialMedia.h"
#import "MMInterstitial.h"
#import "MMRequest.h"
#import "ANGlobal.h"
#import "ANLogging.h"

@interface ANAdAdapterInterstitialMillennialMedia ()
@property (nonatomic, readwrite, strong) MMInterstitial *interstitialAd;
@property (nonatomic, readwrite, strong) NSString *apid;
@end

@implementation ANAdAdapterInterstitialMillennialMedia
@synthesize delegate;

#pragma mark ANCustomAdapterInterstitial

- (void)requestInterstitialAdWithParameter:(NSString *)parameterString
                                  adUnitId:(NSString *)idString
                                  location:(ANLocation *)location
{
    ANLogDebug(@"Requesting MillennialMedia interstitial");
    [MMSDK initialize];
    [self addMMNotificationObservers];
    
    self.apid = idString;
    
    if ([MMInterstitial isAdAvailableForApid:self.apid]) {
        ANLogInfo(@"MillennialMedia interstitial was already available, attempting to load cached ad");
        [self.delegate didLoadInterstitialAd:self];
        return;
    }
    
    //MMRequest object
    MMRequest *request;
    if (location) {
        CLLocation *locToSend = [[CLLocation alloc]
                     initWithCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)
                     altitude:0
                     horizontalAccuracy:location.horizontalAccuracy
                     verticalAccuracy:0 course:0 speed:0
                     timestamp:location.timestamp];
        
        request = [MMRequest requestWithLocation:locToSend];
    }
    else {
        request = [MMRequest request];
    }
    
    [MMInterstitial fetchWithRequest:request
                                apid:idString
                        onCompletion:^(BOOL success, NSError *error) {
                            if (success) {
                                ANLogDebug(@"MillennialMedia interstitial did load");
                                [self.delegate didLoadInterstitialAd:self];
                            } else {
                                ANLogWarn(@"MillennialMedia interstitial failed to load with error: %@", error);
                                ANAdResponseCode code = ANAdResponseInternalError;
                                
                                switch (error.code) {
                                    case MMAdUnknownError:
                                        code = ANAdResponseInternalError;
                                        break;
                                    case MMAdServerError:
                                        code = ANAdResponseNetworkError;
                                        break;
                                    case MMAdUnavailable:
                                        code = ANAdResponseUnableToFill;
                                        break;
                                    case MMAdDisabled:
                                        code = ANAdResponseInvalidRequest;
                                        break;
                                    default:
                                        code = ANAdResponseInternalError;
                                        break;
                                }
                                
                                [self.delegate didFailToLoadAd:code];
                            }
                        }];
    
    
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    if (![MMInterstitial isAdAvailableForApid:self.apid]) {
        ANLogWarn(@"MillennialMedia interstitial no longer available, failed to present ad");
        [self.delegate failedToDisplayAd];
        return;
    }
    
    ANLogDebug(@"Showing MillennialMedia interstitial");
    [MMInterstitial displayForApid:self.apid
                fromViewController:viewController
                   withOrientation:0
                      onCompletion:^(BOOL success, NSError *error) {
                          if (!success) {
                              ANLogWarn(@"MillennialMedia interstitial call to display ad failed");
                              [self.delegate failedToDisplayAd];
                          }
                      }];
}

@end