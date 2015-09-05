//
//  SKDeviceMotion.m
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

#import "SKDeviceMotion.h"
#import "SKMotionManager.h"
#import "SKDeviceMotionData.h"


@interface SKDeviceMotion ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end


@implementation SKDeviceMotion

- (instancetype)initWithConfiguration:(SKDeviceMotionConfiguration *)configuration
{
    if (self = [super init])
    {
        self.motionManager = [SKMotionManager sharedMotionManager];
        
        // Set the configuration
        [self setConfiguration:configuration];
    }
    return self;
}


#pragma mark Configuration

- (void)setConfiguration:(SKConfiguration *)configuration
{
    // Check if the correct configuration type provided
    if (configuration.class != SKDeviceMotionConfiguration.class)
    {
        NSLog(@"Wrong SKConfiguration class provided (%@) for sensor DeviceMotion.", configuration.class);
        abort();
    }
    
    if (self.configuration != configuration)
    {
        [super setConfiguration:configuration];
        
        // Case the configuration instance
        SKDeviceMotionConfiguration *deviceMotionConfiguration = (SKDeviceMotionConfiguration *)configuration;
        
        // Make the required updates on the sensor
        self.motionManager.deviceMotionUpdateInterval = 1.0 / deviceMotionConfiguration.samplingRate;  // Convert Hz into interval
    }
}


#pragma mark Sensing

+ (BOOL)isSensorAvailable
{
    return [SKMotionManager sharedMotionManager].isDeviceMotionAvailable;
}

- (void)startSensing
{
    [super startSensing];

    if ([self.motionManager isDeviceMotionAvailable])
    {
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                                withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                    
                                                    if (error) {
                                                        NSLog(@"%@", error.localizedDescription);
                                                    } else {
                                                        SKDeviceMotionData *data = [[SKDeviceMotionData alloc] initWithDeviceMotion:motion];
                                                        [self submitSensorData:data];
                                                    }
                                                    
                                                }];
    }
    else
    {
        NSLog(@"DeviceMotion Sensing is not available.");
        abort();
    }
}

- (void)stopSensing
{
    [self.motionManager stopDeviceMotionUpdates];
    
    [super stopSensing];
}

@end
