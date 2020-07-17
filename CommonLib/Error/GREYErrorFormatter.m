//
// Copyright 2020 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYErrorFormatter.h"

#import "GREYFatalAsserts.h"
#import "GREYError+Private.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYObjectFormatter.h"
#import "NSError+GREYCommon.h"

#pragma mark - UI Hierarchy Keys

static NSString *const kHierarchyHeaderKey = @"UI Hierarchy (Back to front):\n";
static NSString *const kErrorPrefix = @"EarlGrey Encountered an Error:";

#pragma mark - GREYErrorFormatter

@implementation GREYErrorFormatter

#pragma mark - Public Methods

+ (NSString *)formattedDescriptionForError:(GREYError *)error {
  if (GREYShouldUseErrorFormatterForError(error)) {
    return LoggerDescription(error);
  } else {
    return [GREYObjectFormatter formatDictionary:[error grey_descriptionDictionary]
                                          indent:kGREYObjectFormatIndent
                                       hideEmpty:YES
                                        keyOrder:nil];
  }
}

#pragma mark - Public Functions

BOOL GREYShouldUseErrorFormatterForError(GREYError *error) {
  return ([error.domain isEqualToString:kGREYInteractionErrorDomain] &&
          (error.code == kGREYInteractionElementNotFoundErrorCode ||
           error.code == kGREYInteractionMultipleElementsMatchedErrorCode ||
           error.code == kGREYInteractionActionFailedErrorCode ||
           error.code == kGREYInteractionAssertionFailedErrorCode ||
           error.code == kGREYInteractionConstraintsFailedErrorCode ||
           error.code == kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode ||
           error.code == kGREYInteractionTimeoutErrorCode ||
           error.code == kGREYWKWebViewInteractionFailedErrorCode)) ||
         [error.domain isEqualToString:kGREYSyntheticEventInjectionErrorDomain] ||
         [error.domain isEqualToString:kGREYUIThreadExecutorErrorDomain] ||
         [error.domain isEqualToString:kGREYKeyboardDismissalErrorDomain] ||
         [error.domain isEqualToString:kGREYIntializationErrorDomain];
}

BOOL GREYShouldUseErrorFormatterForDetails(NSString *failureHandlerDetails) {
  return [failureHandlerDetails hasPrefix:kErrorPrefix];
}

#pragma mark - Static Functions

static NSString *LoggerDescription(GREYError *error) {
  NSMutableString *logger = [[NSMutableString alloc] init];
  // Flag checked by GREYErrorFormatted(details, screenshotPaths).
  // TODO(wsaid): remove this when the GREYErrorFormatted(details, screenshotPaths) is removed
  [logger appendString:kErrorPrefix];
  NSString *exceptionReason = error.localizedDescription;
  if (exceptionReason) {
    [logger appendFormat:@"\n\n%@", exceptionReason];
  }

  NSString *recoverySuggestion = error.userInfo[kErrorDetailRecoverySuggestionKey];
  if (recoverySuggestion) {
    [logger appendFormat:@"\n\n%@", recoverySuggestion];
  }

  NSString *elementMatcher = error.userInfo[kErrorDetailElementMatcherKey];
  if (elementMatcher) {
    [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailElementMatcherKey, elementMatcher];
  }

  NSString *failedConstraints = error.userInfo[kErrorDetailConstraintRequirementKey];
  if (failedConstraints) {
    [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailConstraintRequirementKey, failedConstraints];
  }

  NSString *elementDescription = error.userInfo[kErrorDetailElementDescriptionKey];
  if (elementDescription) {
    [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailElementDescriptionKey, elementDescription];
  }

  NSString *assertionCriteria = error.userInfo[kErrorDetailAssertCriteriaKey];
  if (assertionCriteria) {
    [logger appendFormat:@"\n\n%@: %@", kErrorDetailAssertCriteriaKey, assertionCriteria];
  }
  NSString *actionCriteria = error.userInfo[kErrorDetailActionNameKey];
  if (actionCriteria) {
    [logger appendFormat:@"\n\n%@: %@", kErrorDetailActionNameKey, actionCriteria];
  }

  NSArray<NSString *> *multipleElementsMatched = error.multipleElementsMatched;
  if (multipleElementsMatched) {
    [logger appendFormat:@"\n\n%@:", kErrorDetailElementsMatchedKey];
    [multipleElementsMatched
        enumerateObjectsUsingBlock:^(NSString *element, NSUInteger index, BOOL *stop) {
          // Numbered list of all elements that were matched, starting at 1.
          [logger appendFormat:@"\n\n\t%lu. %@", (unsigned long)index + 1, element];
        }];
  }

  NSString *searchActionInfo = error.userInfo[kErrorDetailSearchActionInfoKey];
  if (searchActionInfo) {
    [logger appendFormat:@"\n\n%@\n%@", kErrorDetailSearchActionInfoKey, searchActionInfo];
  }

  NSString *nestedError = error.nestedError.description;
  if (nestedError) {
    [logger appendFormat:@"\n\nUnderlying Error:\n%@", nestedError];
  }

  NSString *hierarchy = error.appUIHierarchy;
  if (hierarchy) {
    [logger appendFormat:@"\n\n%@\n%@", kHierarchyHeaderKey, hierarchy];
  }

  return [NSString stringWithFormat:@"%@\n", logger];
}

@end