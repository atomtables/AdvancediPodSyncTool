//
//  STiPodWatcher.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 3/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "STiPodWatcher.h"
#import <sys/param.h>
#import <sys/mount.h>
#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>

@implementation STiPodWatcher

- (id)init {
    if (self = [super init]) [self instantiate];
    return self;
}

- (void)instantiate {
    NSLog(@"instantiating self now");
    
    self.connectedDevices = [[NSMutableDictionary alloc] init];
    
    // this is for new devices
    NSNotificationCenter* notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    self.connectedObserver = [notificationCenter addObserverForName:NSWorkspaceDidMountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification* note) {
        
        NSMutableDictionary* vendorModel = [self getVendorAndModelForIOService:[self getIOServiceForMountedURL:note.userInfo[NSWorkspaceVolumeURLKey]]];
        vendorModel[@"mountPoint"] = note.userInfo[NSWorkspaceVolumeURLKey];
        
        self.connectedDevices[vendorModel[@"serialNumber"]] = vendorModel;
        NSLog(@"connectedDevices update: %@", self.connectedDevices);
    }];
    
    self.disconnectedObserver = [notificationCenter addObserverForName:NSWorkspaceDidUnmountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification* note){
        NSString* serialNumberOfRemovedDevice;
        for (NSString* sn in self.connectedDevices) {
            if ([self.connectedDevices[sn][@"mountPoint"] isEqualToString:note.userInfo[NSWorkspaceVolumeURLKey]]){
                serialNumberOfRemovedDevice = sn;
                break;
            }
        }
        if (serialNumberOfRemovedDevice) self.connectedDevices[serialNumberOfRemovedDevice] = nil;
    }];
    
    // this is for existing devices
    NSArray* urls = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:@[NSURLVolumeNameKey] options:0];
    for (NSURL* url in urls) {
        NSMutableDictionary* vendorModel = [self getVendorAndModelForIOService:[self getIOServiceForMountedURL:url]];
        vendorModel[@"mountPoint"] = url;
        NSLog(@"url: %@, dict: %@", url, vendorModel);
        
        if (vendorModel[@"serialNumber"] == nil) continue;
        self.connectedDevices[vendorModel[@"serialNumber"]] = vendorModel;
        NSLog(@"connectedDevices update: %@", self.connectedDevices);
    }
}

- (CFDictionaryRef)getIOServiceForMountedURL:(NSURL*)url {
    NSURL *volumeURL = nil;
    NSError *error = nil;
    
    if ([url getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:&error]) {
        struct statfs statkey;
        if (statfs([volumeURL fileSystemRepresentation], &statkey) == 0) {
            // IOBSDNameMatching doesn't take /dev...
            const char* bsdName = statkey.f_mntfromname;
            if (strncmp(bsdName, "/dev/", 5) == 0) {
                bsdName += 5;
            }
            return (IOBSDNameMatching(kIOMasterPortDefault, 0, bsdName));
        }
        
    }
    
    return nil;
}

- (NSMutableDictionary*)getVendorAndModelForIOService:(CFDictionaryRef)ioService {
    NSMutableDictionary* ret = [[NSMutableDictionary alloc] init];
    
    io_iterator_t iter;
    kern_return_t kr = IOServiceGetMatchingServices(kIOMasterPortDefault, ioService, &iter);
    if (kr != KERN_SUCCESS) return nil;
    
    io_service_t device;
    while ((device = IOIteratorNext(iter))) {
        NSLog(@"got new device: %x", device);
        CFNumberRef vendorIdRef = (CFNumberRef)IORegistryEntrySearchCFProperty(device, kIOServicePlane, CFSTR("idVendor"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents);
        if (vendorIdRef) {
            int vendorId = 0;
            
            CFNumberGetValue(vendorIdRef, kCFNumberIntType, &vendorId);
            CFRelease(vendorIdRef);
            ret[@"vendorId"] = @(vendorId);
            NSLog(@"vendorId: %x", vendorId);
        }
        
        CFNumberRef productIdRef = (CFNumberRef)IORegistryEntrySearchCFProperty(device, kIOServicePlane, CFSTR("idProduct"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents);
        if (productIdRef) {
            int productId = 0;
            
            CFNumberGetValue(productIdRef, kCFNumberIntType, &productId);
            CFRelease(productIdRef);
            ret[@"productId"] = @(productId);
            NSLog(@"productId: %x", productId);
        }
        
        CFStringRef vendorNameRef = (CFStringRef)IORegistryEntrySearchCFProperty(device, kIOServicePlane, CFSTR("USB Vendor Name"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents);
        if (vendorNameRef) {
            char vendorName[256];
            CFStringGetCString(vendorNameRef, vendorName, sizeof(vendorName), kCFStringEncodingUTF8);
            CFRelease(vendorNameRef);
            ret[@"vendorName"] = [NSString stringWithUTF8String:vendorName];
            NSLog(@"vendorName: %s", vendorName);
        }
        
        CFStringRef modelNameRef = (CFStringRef)IORegistryEntrySearchCFProperty(device, kIOServicePlane, CFSTR("USB Product Name"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents);
        if (modelNameRef) {
            char modelName[256];
            CFStringGetCString(modelNameRef, modelName, sizeof(modelName), kCFStringEncodingUTF8);
            CFRelease(modelNameRef);
            ret[@"productName"] = [NSString stringWithUTF8String:modelName];
            NSLog(@"productName: %s", modelName);
        }
        
        CFStringRef serialNumberRef = (CFStringRef)IORegistryEntrySearchCFProperty(device, kIOServicePlane, CFSTR("USB Serial Number"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents);
        if (serialNumberRef) {
            char serialNumber[256];
            CFStringGetCString(serialNumberRef, serialNumber, sizeof(serialNumber), kCFStringEncodingUTF8);
            CFRelease(serialNumberRef);
            ret[@"serialNumber"] = [NSString stringWithUTF8String:serialNumber];
            NSLog(@"serialNumber: %s", serialNumber);
        }
        
        IOObjectRelease(device);
    }
    IOObjectRelease(iter);
    
    return ret;
}

- (void)dealloc {
    if (self.connectedObserver) [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self.connectedObserver];
}

@end
