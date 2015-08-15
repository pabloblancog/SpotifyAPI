//
//  SpotifyAPI.h
//  Setlists
//
//  Created by Pablo Blanco González on 09/05/14.
//  Copyright (c) 2014 Pablo Blanco González. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>
#import "AppDelegate.h"

@interface SpotifyAPI : NSObject

// Session methods
+(SPTSession*)getSavedSession;
+(void)saveSession:(SPTSession*)session;
+(void)clearSession;
+(void)renewSessionWithSuccess:(void (^)(SPTSession*))success
                    andFailure:(void (^)(NSError*)) failure
                   andProgress:(void (^)(void))progress;
+(void)getUserInfoWithSuccess:(void (^)(SPTUser *))success
                   andFailure:(void (^)(NSError *))failure
                  andProgress:(void (^)(void))progress;
+(void)logoutWithSuccess:(void (^)(void))success
              andFailure:(void (^)(NSError*))failure;

// Artist Image URL search
+(void)getArtistImageWithImageURL:(NSString*)imageURL
               AndNumberOfRetries:(NSInteger)numberOfRetries
                      WithSuccess:(void (^)(UIImageView*))success
                       andFailure:(void (^)(NSError*))failure;

// Artist search
+(void)findArtist:(NSString *)artistQuery
         withPage:(NSInteger)page
AndNumberOfRetries:(NSInteger)numberOfRetries
   AndWithSuccess:(void (^)(NSData *artists))success
       andFailure:(void (^)(NSError *))failure;

// Track search
+(void)findTrackWithSongTitle:(NSString*)songTitle
                andSongArtist:(NSString*)artist
           AndNumberOfRetries:(NSInteger)numberOfRetries
               AndWithSuccess:(void (^)(NSData *tracks))success
                   andFailure:(void (^)(NSError *))failure;

+(void)createSpotifyTracksWithSpotifyURIs:(NSArray*) spotifyURIs
                              WithSuccess:(void (^)(NSArray *spotifyTracks))success
                               andFailure:(void (^)(NSError *))failure;

// Playlist creation
+(void)createPlaylistWithTracks:(NSArray *)tracks
               WithPlaylistName:(NSString*)playlistName
                    WithSuccess:(void (^)(SPTPlaylistSnapshot*))success
                     andFailure:(void (^)(NSError *))failure;

@end
