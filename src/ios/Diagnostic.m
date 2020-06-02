/*
 *  Diagnostic.h
 *  Plugin diagnostic
 *
 *  Copyright (c) 2015 Working Edge Ltd.
 *  Copyright (c) 2012 AVANTIC ESTUDIO DE INGENIEROS
 */

#import "Diagnostic.h"
#import <AVFoundation/AVFoundation.h>

#import <arpa/inet.h> // For AF_INET, etc.
#import <ifaddrs.h> // For getifaddrs()
#import <net/if.h> // For IFF_LOOPBACK



@implementation Diagnostic

- (void)pluginInitialize {
    
    [super pluginInitialize];

    self.locationRequestCallbackId = nil;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.bluetoothManager = [[CBCentralManager alloc]
                             initWithDelegate:self
                             queue:dispatch_get_main_queue()
                             options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
    [self centralManagerDidUpdateState:self.bluetoothManager]; // Show initial state
}

/*************
 * Plugin API
 *************/

// Location
- (void) isLocationAvailable: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if([CLLocationManager locationServicesEnabled] && [self isLocationAuthorized]) {
            NSLog(@"Location is available.");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        }
        else {
            NSLog(@"Location is not available.");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) isLocationEnabled: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if([CLLocationManager locationServicesEnabled]) {
            NSLog(@"Location setting is enabled");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        }
        else {
            NSLog(@"Location setting is disabled");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}


- (void) isLocationAuthorized: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if([self isLocationAuthorized]) {
            NSLog(@"This app is authorized to use location.");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        } else {
            NSLog(@"This app is not authorized to use location.");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void) getLocationAuthorizationStatus: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        NSString* status = [self getLocationAuthorizationStatusAsString:[CLLocationManager authorizationStatus]];
        NSLog([NSString stringWithFormat:@"Location authorization status is: %@", status]);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:status];
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void) requestLocationAuthorization: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if ([CLLocationManager instancesRespondToSelector:@selector(requestWhenInUseAuthorization)])
        {
            BOOL always = [[command argumentAtIndex:0] boolValue];
            if(always){
                NSAssert([[[NSBundle mainBundle] infoDictionary] valueForKey:@"NSLocationAlwaysUsageDescription"], @"For iOS 8 and above, your app must have a value for NSLocationAlwaysUsageDescription in its Info.plist");
                [self.locationManager requestAlwaysAuthorization];
                NSLog(@"Requesting location authorization: always");
            }else{
                NSAssert([[[NSBundle mainBundle] infoDictionary] valueForKey:@"NSLocationWhenInUseUsageDescription"], @"For iOS 8 and above, your app must have a value for NSLocationWhenInUseUsageDescription in its Info.plist");
                [self.locationManager requestWhenInUseAuthorization];
                NSLog(@"Requesting location authorization: when in use");
            }
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    self.locationRequestCallbackId = command.callbackId;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Wifi
- (void) isWifiAvailable: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if([self connectedToWifi]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Bluetooth
- (void) isBluetoothAvailable: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if(self.bluetoothEnabled) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
            
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
            
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getBluetoothState: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        NSString* state = self.bluetoothState;
        NSLog([NSString stringWithFormat:@"Bluetooth state is: %@", state]);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:state];
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

// Settings
- (void) switchToSettings: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    @try {
        if (UIApplicationOpenSettingsURLString != nil && &UIApplicationOpenSettingsURLString != NULL){
            [[UIApplication sharedApplication] openURL: [NSURL URLWithString: UIApplicationOpenSettingsURLString]];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }else{
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported below iOS 8"];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Remote (Push) Notifications
- (void) isRemoteNotificationsEnabled: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    BOOL isEnabled;
    @try {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            // iOS8+
            BOOL remoteNotificationsEnabled = [UIApplication sharedApplication].isRegisteredForRemoteNotifications;
            UIUserNotificationSettings *userNotificationSettings = [UIApplication sharedApplication].currentUserNotificationSettings;
            isEnabled = remoteNotificationsEnabled && userNotificationSettings.types != UIUserNotificationTypeNone;
        } else {
            // iOS7 and below
            UIRemoteNotificationType enabledRemoteNotificationTypes = [UIApplication sharedApplication].enabledRemoteNotificationTypes;
            isEnabled = enabledRemoteNotificationTypes != UIRemoteNotificationTypeNone;
        }
        
        if(isEnabled) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getRemoteNotificationTypes: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    BOOL noneEnabled,alertsEnabled, badgesEnabled, soundsEnabled;
    @try {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            // iOS8+
            UIUserNotificationSettings *userNotificationSettings = [UIApplication sharedApplication].currentUserNotificationSettings;
            noneEnabled = userNotificationSettings.types == UIUserNotificationTypeNone;
            alertsEnabled = userNotificationSettings.types & UIUserNotificationTypeAlert;
            badgesEnabled = userNotificationSettings.types & UIUserNotificationTypeBadge;
            soundsEnabled = userNotificationSettings.types & UIUserNotificationTypeSound;
        } else {
            // iOS7 and below
            UIRemoteNotificationType enabledRemoteNotificationTypes = [UIApplication sharedApplication].enabledRemoteNotificationTypes;
            noneEnabled = enabledRemoteNotificationTypes == UIRemoteNotificationTypeNone;
            alertsEnabled = enabledRemoteNotificationTypes & UIRemoteNotificationTypeAlert;
            badgesEnabled = enabledRemoteNotificationTypes & UIRemoteNotificationTypeBadge;
            soundsEnabled = enabledRemoteNotificationTypes & UIRemoteNotificationTypeSound;
        }
        
        NSMutableDictionary* types = [[NSMutableDictionary alloc]init];
        if(alertsEnabled) {
            [types setValue:@"1" forKey:@"alert"];
        } else {
            [types setValue:@"0" forKey:@"alert"];
        }
        if(badgesEnabled) {
            [types setValue:@"1" forKey:@"badge"];
        } else {
            [types setValue:@"0" forKey:@"badge"];
        }
        if(soundsEnabled) {
            [types setValue:@"1" forKey:@"sound"];
        } else {;
            [types setValue:@"0" forKey:@"sound"];
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self objectToJsonString:types]];
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) isRegisteredForRemoteNotifications: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    BOOL registered;
    @try {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            // iOS8+
            registered = [UIApplication sharedApplication].isRegisteredForRemoteNotifications;
        } else {
            // iOS7 and below
            UIRemoteNotificationType enabledRemoteNotificationTypes = [UIApplication sharedApplication].enabledRemoteNotificationTypes;
            registered = enabledRemoteNotificationTypes != UIRemoteNotificationTypeNone;
        }
        if(registered) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/*********************
 * Internal functions
 *********************/
- (void)jsCallback: (NSString*)jsString
{
    [self.commandDelegate evalJs:jsString];
}

- (NSString*) getLocationAuthorizationStatusAsString: (CLAuthorizationStatus)authStatus
{
    NSString* status;
    if(authStatus == kCLAuthorizationStatusDenied || authStatus == kCLAuthorizationStatusRestricted){
        status = @"denied";
    }else if(authStatus == kCLAuthorizationStatusNotDetermined){
        status = @"not_determined";
    }else if(authStatus == kCLAuthorizationStatusAuthorizedAlways){
        status = @"authorized";
    }else if(authStatus == kCLAuthorizationStatusAuthorizedWhenInUse){
        status = @"authorized_when_in_use";
    }
    return status;
}

- (BOOL) isLocationAuthorized
{
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    NSString* status = [self getLocationAuthorizationStatusAsString:authStatus];
    if([status  isEqual: @"authorized"] || [status  isEqual: @"authorized_when_in_use"]) {
        return true;
    } else {
        return false;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)authStatus {
    NSString* status = [self getLocationAuthorizationStatusAsString:authStatus];
    NSLog([NSString stringWithFormat:@"Location authorization status changed to: %@", status]);

    if(self.locationRequestCallbackId != nil){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:status];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.locationRequestCallbackId];
        self.locationRequestCallbackId = nil;
    }

    [self jsCallback:[NSString stringWithFormat:@"cordova.plugins.diagnostic._onLocationStateChange(\"%@\");", status]];
}

- (BOOL) connectedToWifi  // Don't work on iOS Simulator, only in the device
{
    struct ifaddrs *addresses;
    struct ifaddrs *cursor;
    BOOL wiFiAvailable = NO;
    
    if (getifaddrs(&addresses) != 0) {
        return NO;
    }
    
    cursor = addresses;
    while (cursor != NULL)  {
        if (cursor -> ifa_addr -> sa_family == AF_INET && !(cursor -> ifa_flags & IFF_LOOPBACK)) // Ignore the loopback address
        {
            // Check for WiFi adapter
            if (strcmp(cursor -> ifa_name, "en0") == 0) {
                
                NSLog(@"Wifi ON");
                wiFiAvailable = YES;
                break;
            }
        }
        cursor = cursor -> ifa_next;
    }
    freeifaddrs(addresses);
    return wiFiAvailable;
}

- (NSString*) arrayToJsonString:(NSArray*)inputArray
{
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:inputArray options:NSJSONWritingPrettyPrinted error:&error];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (NSString*) objectToJsonString:(NSDictionary*)inputObject
{
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:inputObject options:NSJSONWritingPrettyPrinted error:&error];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

#pragma mark - CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString* state;
    NSString* description;
    
    switch(self.bluetoothManager.state)
    {
        case CBCentralManagerStateResetting:
            state = @"resetting";
            description =@"The connection with the system service was momentarily lost, update imminent.";
            break;
            
        case CBCentralManagerStateUnsupported:
            state = @"unsupported";
            description = @"The platform doesn't support Bluetooth Low Energy.";
            break;
            
        case CBCentralManagerStateUnauthorized:
            state = @"unauthorized";
            description = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"powered_off";
            description = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"powered_on";
            description = @"Bluetooth is currently powered on and available to use.";
            break;
        default:
            state = @"unknown";
            description = @"State unknown, update imminent.";
            break;
    }
    NSLog(@"Bluetooth state changed: %@",description);
    
    self.bluetoothState = state;
    if([state  isEqual: @"powered_on"]){
        self.bluetoothEnabled = true;
    }else{
        self.bluetoothEnabled = false;
    }
    
    NSString* jsString = [NSString stringWithFormat:@"cordova.plugins.diagnostic._onBluetoothStateChange(\"%@\");", state];
    [self jsCallback:jsString];
}

@end
