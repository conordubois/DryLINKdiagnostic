/*
 *  Diagnostic.h
 *  Plugin diagnostic
 *
 *  Copyright (c) 2015 Working Edge Ltd.
 *  Copyright (c) 2012 AVANTIC ESTUDIO DE INGENIEROS
 */

#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <WebKit/WebKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <EventKit/EventKit.h>

@interface Diagnostic : CDVPlugin <CBCentralManagerDelegate, CLLocationManagerDelegate>

    @property (nonatomic, retain) CBCentralManager* bluetoothManager;
    @property (nonatomic) BOOL bluetoothEnabled;
    @property (nonatomic) NSString* bluetoothState;
    @property (strong, nonatomic) CLLocationManager* locationManager;
    @property (nonatomic, retain) NSString* locationRequestCallbackId;
    @property (nonatomic) EKEventStore *eventStore;

- (void) isLocationAvailable: (CDVInvokedUrlCommand*)command;
- (void) isLocationEnabled: (CDVInvokedUrlCommand*)command;
- (void) isLocationAuthorized: (CDVInvokedUrlCommand*)command;
- (void) getLocationAuthorizationStatus: (CDVInvokedUrlCommand*)command;
- (void) requestLocationAuthorization: (CDVInvokedUrlCommand*)command;

- (void) isWifiAvailable: (CDVInvokedUrlCommand*)command;
- (void) isBluetoothAvailable: (CDVInvokedUrlCommand*)command;

- (void) isRemoteNotificationsEnabled: (CDVInvokedUrlCommand*)command;
- (void) getRemoteNotificationTypes: (CDVInvokedUrlCommand*)command;
- (void) isRegisteredForRemoteNotifications: (CDVInvokedUrlCommand*)command;

- (void) switchToSettings: (CDVInvokedUrlCommand*)command;


@end
