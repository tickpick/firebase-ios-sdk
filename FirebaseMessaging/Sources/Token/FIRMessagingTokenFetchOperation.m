/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FIRMessagingTokenFetchOperation.h"

#import "FIRMessagingCheckinPreferences.h"
#import "FIRMessagingConstants.h"
#import "FIRMessagingDefines.h"
#import "FIRMessagingLogger.h"
#import "FIRMessagingTokenOperation+Private.h"
#import "FIRMessagingUtilities.h"
#import "NSError+FIRMessaging.h"

#import "FirebaseCore/Sources/Private/FirebaseCoreInternal.h"

// We can have a static int since this error should theoretically only
// happen once (for the first time). If it repeats there is something
// else that is wrong.
static int phoneRegistrationErrorRetryCount = 0;
static const int kMaxPhoneRegistrationErrorRetryCount = 10;
NSString *const kFIRMessagingFirebaseUserAgentKey = @"X-firebase-client";
NSString *const kFIRMessagingFirebaseHeartbeatKey = @"X-firebase-client-log-type";
NSString *const kFIRMessagingHeartbeatTag = @"fire-iid";

@implementation FIRMessagingTokenFetchOperation

- (instancetype)initWithAuthorizedEntity:(NSString *)authorizedEntity
                                   scope:(NSString *)scope
                                 options:(nullable NSDictionary<NSString *, NSString *> *)options
                      checkinPreferences:(FIRMessagingCheckinPreferences *)checkinPreferences
                              instanceID:(NSString *)instanceID {
  self = [super initWithAction:FIRMessagingTokenActionFetch
           forAuthorizedEntity:authorizedEntity
                         scope:scope
                       options:options
            checkinPreferences:checkinPreferences
                    instanceID:instanceID];
  if (self) {
  }
  return self;
}

- (void)performTokenOperation {
  NSMutableURLRequest *request = [self tokenRequest];
  NSString *checkinVersionInfo = self.checkinPreferences.versionInfo;
  [request setValue:checkinVersionInfo forHTTPHeaderField:@"info"];
  [request setValue:[FIRApp firebaseUserAgent]
      forHTTPHeaderField:kFIRMessagingFirebaseUserAgentKey];
  [request setValue:@([FIRHeartbeatInfo heartbeatCodeForTag:kFIRMessagingHeartbeatTag]).stringValue
      forHTTPHeaderField:kFIRMessagingFirebaseHeartbeatKey];

  // Build form-encoded body
  NSString *deviceAuthID = self.checkinPreferences.deviceID;
  NSMutableArray<NSURLQueryItem *> *queryItems =
      [[self class] standardQueryItemsWithDeviceID:deviceAuthID scope:self.scope];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"sender"
                                                               value:self.authorizedEntity]];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"X-subtype"
                                                               value:self.authorizedEntity]];

  if (self.instanceID.length > 0) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:kFIRMessagingParamInstanceID
                                                      value:self.instanceID]];
  }
  // Create query items from passed-in options
  id apnsTokenData = self.options[kFIRMessagingTokenOptionsAPNSKey];
  id apnsSandboxValue = self.options[kFIRMessagingTokenOptionsAPNSIsSandboxKey];
  if ([apnsTokenData isKindOfClass:[NSData class]] &&
      [apnsSandboxValue isKindOfClass:[NSNumber class]]) {
    NSString *APNSString = FIRMessagingAPNSTupleStringForTokenAndServerType(
        apnsTokenData, ((NSNumber *)apnsSandboxValue).boolValue);
    // The name of the query item happens to be the same as the dictionary key
    NSURLQueryItem *item =
        [NSURLQueryItem queryItemWithName:kFIRMessagingTokenOptionsAPNSKey
                                               value:APNSString];
    [queryItems addObject:item];
  }
  id firebaseAppID = self.options[kFIRMessagingTokenOptionsFirebaseAppIDKey];
  if ([firebaseAppID isKindOfClass:[NSString class]]) {
    // The name of the query item happens to be the same as the dictionary key
    NSURLQueryItem *item =
        [NSURLQueryItem queryItemWithName:kFIRMessagingTokenOptionsFirebaseAppIDKey
                                               value:(NSString *)firebaseAppID];
    [queryItems addObject:item];
  }

  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.queryItems = queryItems;
  NSString *content = components.query;
  request.HTTPBody = [content dataUsingEncoding:NSUTF8StringEncoding];
  FIRMessagingLoggerDebug(kFIRMessagingMessageCodeTokenFetchOperationFetchRequest,
                           @"Register request to %@ content: %@", FIRMessagingTokenRegisterServer(),
                           content);

  FIRMessaging_WEAKIFY(self);
  void (^requestHandler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        FIRMessaging_STRONGIFY(self);
        [self handleResponseWithData:data response:response error:error];
      };


  NSURLSession *session = [FIRMessagingTokenOperation sharedURLSession];
  self.dataTask = [session dataTaskWithRequest:request completionHandler:requestHandler];
  [self.dataTask resume];
}

#pragma mark - Request Handling

- (void)handleResponseWithData:(NSData *)data
                      response:(NSURLResponse *)response
                         error:(NSError *)error {
  if (error) {
    FIRMessagingLoggerDebug(kFIRMessagingMessageCodeTokenFetchOperationRequestError,
                             @"Token fetch HTTP error. Error Code: %ld", (long)error.code);
    [self finishWithResult:FIRMessagingTokenOperationError token:nil error:error];
    return;
  }
  NSString *dataResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

  if (dataResponse.length == 0) {
    NSError *error = [NSError errorWithFIRMessagingErrorCode:kFIRMessagingErrorCodeUnknown];
    [self finishWithResult:FIRMessagingTokenOperationError token:nil error:error];
    return;
  }
  NSDictionary *parsedResponse = [self parseFetchTokenResponse:dataResponse];

  if ([parsedResponse[@"token"] length]) {
    [self finishWithResult:FIRMessagingTokenOperationSucceeded
                     token:parsedResponse[@"token"]
                     error:nil];
    return;
  }

  NSString *errorValue = parsedResponse[@"Error"];
  NSError *responseError;
  if (errorValue.length) {
    NSArray *errorComponents = [errorValue componentsSeparatedByString:@":"];
    // HACK (Kansas replication delay), PHONE_REGISTRATION_ERROR on App
    // uninstall and reinstall.
    if ([errorComponents containsObject:@"PHONE_REGISTRATION_ERROR"]) {
      // Encountered issue http://b/27043795
      // Retry register until successful or another error encountered or a
      // certain number of tries are over.

      if (phoneRegistrationErrorRetryCount < kMaxPhoneRegistrationErrorRetryCount) {
        const int nextRetryInterval = 1 << phoneRegistrationErrorRetryCount;
        FIRMessaging_WEAKIFY(self);

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(nextRetryInterval * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
              FIRMessaging_STRONGIFY(self);
              phoneRegistrationErrorRetryCount++;
              [self performTokenOperation];
            });
        return;
      }
    } else if ([errorComponents containsObject:kFIRMessaging_CMD_RST]) {
      // Server detected the identity we use is no longer valid.
      NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
      [center postNotificationName:kFIRMessagingIdentityInvalidatedNotification object:nil];

      FIRMessagingLoggerDebug(kFIRMessagingMessageCodeInternal001,
                               @"Identity is invalid. Server request identity reset.");
      responseError =
          [NSError errorWithFIRMessagingErrorCode:kFIRMessagingErrorCodeInvalidIdentity];
    }
  }
  if (!responseError) {
    FIRMessagingLoggerDebug(kFIRMessagingMessageCodeTokenFetchOperationBadResponse,
                             @"Invalid fetch response, expected 'token' or 'Error' key");
    responseError = [NSError errorWithFIRMessagingErrorCode:kFIRMessagingErrorCodeUnknown];
  }
  [self finishWithResult:FIRMessagingTokenOperationError token:nil error:responseError];
}

// expect a response e.g. "token=<reg id>\nGOOG.ttl=123"
- (NSDictionary *)parseFetchTokenResponse:(NSString *)response {
  NSArray *lines = [response componentsSeparatedByString:@"\n"];
  NSMutableDictionary *parsedResponse = [NSMutableDictionary dictionary];
  for (NSString *line in lines) {
    NSArray *keyAndValue = [line componentsSeparatedByString:@"="];
    if ([keyAndValue count] > 1) {
      parsedResponse[keyAndValue[0]] = keyAndValue[1];
    }
  }
  return parsedResponse;
}

@end
