//
//  RestHandler.m
//  TVOSExample
//
//  Created by Christian Lysne on 13/09/15.
//  Copyright © 2015 Christian Lysne. All rights reserved.
//

#import "RestHandler.h"
#import "Movie.h"


#define FEED_URL @"https://www.spritle.com/tvOS/json/rails_casts.json"
@implementation RestHandler

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static RestHandler *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RestHandler alloc] init];
    });
    return sharedInstance;
}

- (void)fetchMovies:(void (^)(NSArray *movies))success failure:(void (^)(NSError *error))failure {
    
    NSURL *url = [NSURL URLWithString:FEED_URL];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:30.0f];
    
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if ([data length] > 0 && error == nil){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSError *error = nil;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                NSArray *results = [dict objectForKey:@"results"];
                
                if (results != nil) {
                    
                    NSMutableArray *returnArray = [NSMutableArray new];
                    
                    for (NSDictionary *resultDict in results) {
                        
                        Movie *movie = [Movie new];
                        movie.title = [resultDict objectForKey:@"title"];
                        movie.imageURL = [resultDict objectForKey:@"preview_image"];
                        movie.videoURL=[resultDict objectForKey:@"video_url"];

                        
                        [returnArray addObject:movie];
                    }
                    
                    success(returnArray);
                    
                } else if (error != nil) {
                    
                    NSLog(@"Error: %@", error);
                    
                    failure(error);
                    
                }
                
            });
            
        } else if ([data length] == 0 && error == nil){
            
            NSLog(@"Empty Response");
            
            failure(error);
            
        } else if (error != nil){
            
            NSLog(@"An error occured: %@", error);
            
            failure(error);
            
        }
    }];
    
    [downloadTask resume];
}

@end
