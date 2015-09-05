//
//  SKSensorManager.m
//  SensingKit
//
//  Copyright (c) 2014. Queen Mary University of London
//  Kleomenis Katevas, k.katevas@qmul.ac.uk
//
//  This file is part of SensingKit-iOS library.
//  For more information, please visit http://www.sensingkit.org
//
//  SensingKit-iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SensingKit-iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with SensingKit-iOS.  If not, see <http://www.gnu.org/licenses/>.
//

#import "SKSensorManager.h"
#import "SKAbstractSensor.h"
#import "NSString+SensorType.h"

// Sensors
#import "SKAccelerometer.h"
#import "SKGyroscope.h"
#import "SKMagnetometer.h"
#import "SKDeviceMotion.h"
#import "SKActivity.h"
#import "SKPedometer.h"
#import "SKAltimeter.h"
#import "SKBattery.h"
#import "SKLocation.h"
#import "SKiBeaconProximity.h"
#import "SKEddystoneProximity.h"

// SensorData
#import "SKAccelerometerData.h"
#import "SKGyroscopeData.h"
#import "SKMagnetometerData.h"
#import "SKDeviceMotionData.h"
#import "SKActivityData.h"
#import "SKPedometerData.h"
#import "SKAltimeterData.h"
#import "SKBatteryData.h"
#import "SKLocationData.h"
#import "SKBeaconDeviceData.h"
#import "SKEddystoneProximityData.h"

// SensorConfiguration
#import "SKAccelerometerConfiguration.h"
#import "SKGyroscopeConfiguration.h"
#import "SKMagnetometerConfiguration.h"
#import "SKDeviceMotionConfiguration.h"
#import "SKActivityConfiguration.h"
#import "SKPedometerConfiguration.h"
#import "SKAltimeterConfiguration.h"
#import "SKBatteryConfiguration.h"
#import "SKLocationConfiguration.h"
#import "SKiBeaconProximityConfiguration.h"
#import "SKEddystoneProximityConfiguration.h"

@interface SKSensorManager()

@property (nonatomic, strong, readonly) NSMutableArray *sensors;

@end

@implementation SKSensorManager

- (instancetype)init
{
    if (self = [super init])
    {
        // init array that holds the sensors
        _sensors = [[NSMutableArray alloc] initWithCapacity:TOTAL_SENSORS];
        
        for (NSInteger i = 0; i < TOTAL_SENSORS; i++) {
            [_sensors addObject:[NSNull null]];
        }
    }
    return self;
}


#pragma mark Sensor Status methods

- (BOOL)isSensorAvailable:(SKSensorType)sensorType
{
    switch (sensorType) {
            
        case Accelerometer:
            return [SKAccelerometer isSensorAvailable];
            
        case Gyroscope:
            return [SKGyroscope isSensorAvailable];
            
        case Magnetometer:
            return [SKMagnetometer isSensorAvailable];
            
        case DeviceMotion:
            return [SKDeviceMotion isSensorAvailable];
            
        case Activity:
            return [SKActivity isSensorAvailable];
            
        case Pedometer:
            return [SKPedometer isSensorAvailable];
            
        case Altimeter:
            return [SKAltimeter isSensorAvailable];
            
        case Battery:
            return [SKBattery isSensorAvailable];
            
        case Location:
            return [SKLocation isSensorAvailable];
            
        case iBeaconProximity:
            return [SKiBeaconProximity isSensorAvailable];
            
        case EddystoneProximity:
            return [SKEddystoneProximity isSensorAvailable];
            
        default:
            NSLog(@"Unknown Sensor: %li", (long)sensorType);
            abort();
    }
    
    return NO;
}

- (BOOL)isSensorRegistered:(SKSensorType)sensorType
{
    return ([self.sensors objectAtIndex:sensorType] != [NSNull null]);
}

- (BOOL)isSensorSensing:(SKSensorType)sensorType
{
    return [[self getSensor:sensorType] isSensing];
}


#pragma mark Sensor Registration and Configuration methods

- (void)registerSensor:(SKSensorType)sensorType withConfiguration:(SKConfiguration *)configuration
{
    NSLog(@"Register sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    if ([self isSensorRegistered:sensorType]) {
        
        NSLog(@"Sensor is already registered.");
        abort();
    }
    
    // If configuration was not provided, get the Default
    if (!configuration) {
        configuration = [SKSensorManager defaultConfigurationForSensor:sensorType];
    }
    
    SKAbstractSensor *sensor = [self createSensor:sensorType withConfiguration:configuration];
    [self.sensors replaceObjectAtIndex:sensorType withObject:sensor];
}

- (void)deregisterSensor:(SKSensorType)sensorType
{
    NSLog(@"Deregister sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    if (![self isSensorRegistered:sensorType]) {
        
        NSLog(@"Sensor is not registered.");
        abort();
    }
    
    if ([self isSensorSensing:sensorType]) {
        
        NSLog(@"Sensor is currently sensing.");
        abort();
    }
    
    // Clear all Callbacks from that sensor
    [[self getSensor:sensorType] unsubscribeAllHandlers];
    
    // Deregister the Sensor
    [self.sensors replaceObjectAtIndex:sensorType withObject:[NSNull null]];
}

- (void)setConfiguration:(SKConfiguration *)configuration toSensor:(SKSensorType)sensorType
{
    // If configuration was not provided, get the Default
    if (!configuration) {
        configuration = [SKSensorManager defaultConfigurationForSensor:sensorType];
    }
    
    [[self getSensor:sensorType] setConfiguration:configuration];
}

- (SKConfiguration *)getConfigurationFromSensor:(SKSensorType)sensorType
{
    return [self getSensor:sensorType].configuration;
}


#pragma mark Sensor Subscription and Unsubscription methods

- (void)subscribeToSensor:(SKSensorType)sensorType
              withHandler:(SKSensorDataHandler)handler {
    
    NSLog(@"Subscribe to sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    [[self getSensor:sensorType] subscribeHandler:handler];
}

- (void)unsubscribeFromSensor:(SKSensorType)sensorType
                      handler:(SKSensorDataHandler)handler
{
    NSLog(@"Unsubscribe from sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    [[self getSensor:sensorType] unsubscribeHandler:handler];
}

- (void)unsubscribeAllHandlersFromSensor:(SKSensorType)sensorType
{
    NSLog(@"Unsubscribe all handlers from sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    [[self getSensor:sensorType] unsubscribeAllHandlers];
}

+ (NSString *)csvHeaderForSensor:(SKSensorType)sensorType
{
    switch (sensorType) {
            
        case Accelerometer:
            return [SKAccelerometerData csvHeader];
            
        case Gyroscope:
            return [SKGyroscopeData csvHeader];
            
        case Magnetometer:
            return [SKMagnetometerData csvHeader];
            
        case DeviceMotion:
            return [SKDeviceMotionData csvHeader];
            
        case Activity:
            return [SKActivityData csvHeader];
            
        case Pedometer:
            return [SKPedometerData csvHeader];
            
        case Altimeter:
            return [SKAltimeterData csvHeader];
            
        case Battery:
            return [SKBatteryData csvHeader];
            
        case Location:
            return [SKLocationData csvHeader];
            
        case iBeaconProximity:
            return [SKBeaconDeviceData csvHeader];
            
        case EddystoneProximity:
            return [SKEddystoneProximityData csvHeader];
            
        default:
            NSLog(@"Unknown Sensor: %li", (long)sensorType);
            abort();
    }
}


#pragma mark Continuous Sensing methods

- (void)startContinuousSensingWithSensor:(SKSensorType)sensorType
{
    NSLog(@"Start sensing with sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    if ([self isSensorSensing:sensorType]) {
        
        NSLog(@"Sensor '%@' is already sensing.", [NSString stringWithSensorType:sensorType]);
        abort();
    }
    
    // Start Sensing
    [[self getSensor:sensorType] startSensing];
}

- (void)stopContinuousSensingWithSensor:(SKSensorType)sensorType
{
    NSLog(@"Stop sensing with sensor: %@.", [NSString stringWithSensorType:sensorType]);
    
    if (![self isSensorSensing:sensorType]) {
        
        NSLog(@"Sensor '%@' is already not sensing.", [NSString stringWithSensorType:sensorType]);
        abort();
    }
    
    // Stop Sensing
    [[self getSensor:sensorType] stopSensing];
}

- (void)startContinuousSensingWithAllRegisteredSensors
{
    for (NSInteger i = 0; i < TOTAL_SENSORS; i++) {
        
        SKSensorType sensorType = i;
        
        if ([self isSensorRegistered:sensorType]) {
            [self startContinuousSensingWithSensor:sensorType];
        }
    }
}

- (void)stopContinuousSensingWithAllRegisteredSensors
{
    for (NSInteger i = 0; i < TOTAL_SENSORS; i++) {
        
        SKSensorType sensorType = i;
        
        if ([self isSensorRegistered:sensorType]) {
            [self stopContinuousSensingWithSensor:sensorType];
        }
    }
}


#pragma mark private methods

- (SKAbstractSensor *)getSensor:(SKSensorType)sensorType
{
    if (![self isSensorRegistered:sensorType]) {
        
        NSLog(@"Sensor '%@' is not registered.", [NSString stringWithSensorType:sensorType]);
        abort();
    }
    
    return [self.sensors objectAtIndex:sensorType];
}

- (SKAbstractSensor *)createSensor:(SKSensorType)sensorType withConfiguration:(SKConfiguration *)configuration
{
    SKAbstractSensor *sensor;
    
    switch (sensorType) {
            
        case Accelerometer:
            sensor = [[SKAccelerometer alloc] initWithConfiguration:(SKAccelerometerConfiguration *)configuration];
            
            break;
            
        case Gyroscope:
            sensor = [[SKGyroscope alloc] initWithConfiguration:(SKGyroscopeConfiguration *)configuration];
            break;
            
        case Magnetometer:
            sensor = [[SKMagnetometer alloc] initWithConfiguration:(SKMagnetometerConfiguration *)configuration];
            break;
            
        case DeviceMotion:
            sensor = [[SKDeviceMotion alloc] initWithConfiguration:(SKDeviceMotionConfiguration *)configuration];
            break;
            
        case Activity:
            sensor = [[SKActivity alloc] initWithConfiguration:(SKActivityConfiguration *)configuration];
            break;
            
        case Pedometer:
            sensor = [[SKPedometer alloc] initWithConfiguration:(SKPedometerConfiguration *)configuration];
            break;
            
        case Altimeter:
            sensor = [[SKAltimeter alloc] initWithConfiguration:(SKAltimeterConfiguration *)configuration];
            break;
            
        case Battery:
            sensor = [[SKBattery alloc] initWithConfiguration:(SKBatteryConfiguration *)configuration];
            break;
            
        case Location:
            sensor = [[SKLocation alloc] initWithConfiguration:(SKLocationConfiguration *)configuration];
            break;
            
        case iBeaconProximity:
            sensor = [[SKiBeaconProximity alloc] initWithConfiguration:(SKiBeaconProximityConfiguration *)configuration];
            break;
            
        case EddystoneProximity:
            sensor = [[SKEddystoneProximity alloc] initWithConfiguration:(SKEddystoneProximityConfiguration *)configuration];
            break;
            
            // Don't forget to break!
            
        default:
            NSLog(@"Unknown Sensor: %li", (long)sensorType);
            abort();
    }
    
    return sensor;
}

+ (SKConfiguration *)defaultConfigurationForSensor:(SKSensorType)sensorType
{
    SKConfiguration *configuration;
    
    switch (sensorType) {
            
        case Accelerometer:
            configuration = [[SKAccelerometerConfiguration alloc] init];
            break;
            
        case Gyroscope:
            configuration = [[SKGyroscopeConfiguration alloc] init];
            break;
            
        case Magnetometer:
            configuration = [[SKMagnetometerConfiguration alloc] init];
            break;
            
        case DeviceMotion:
            configuration = [[SKDeviceMotionConfiguration alloc] init];
            break;
            
        case Activity:
            configuration = [[SKActivityConfiguration alloc] init];
            break;
            
        case Pedometer:
            configuration = [[SKPedometerConfiguration alloc] init];
            break;
            
        case Altimeter:
            configuration = [[SKAltimeterConfiguration alloc] init];
            break;
            
        case Battery:
            configuration = [[SKBatteryConfiguration alloc] init];
            break;
            
        case Location:
            configuration = [[SKLocationConfiguration alloc] init];
            break;
            
        case iBeaconProximity:
            configuration = [[SKiBeaconProximityConfiguration alloc] init];
            break;
            
        case EddystoneProximity:
            configuration = [[SKEddystoneProximityConfiguration alloc] init];
            break;
            
            // Don't forget to break!
            
        default:
            NSLog(@"Unknown Sensor: %li", (long)sensorType);
            abort();
    }
    
    return configuration;
}

@end
