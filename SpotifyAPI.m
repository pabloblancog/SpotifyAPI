//
//  SpotifyAPI.m
//  Setlists
//
//  Created by Pablo Blanco González on 09/05/14.
//  Copyright (c) 2014 Pablo Blanco González. All rights reserved.
//

#import "SpotifyAPI.h"
#import <UIImageView+AFNetworking.h>
#import "Config.h"

static const NSString *SPOTIFY_QUERY_URL_BASE = @"https://api.spotify.com/v1/search?query=";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_TYPE = @"&type=";
static const NSString *SPOTIFY_QUERY_URL_OFFSET = @"&offset=";
static const NSString *SPOTIFY_QUERY_URL_LIMIT = @"&limit=";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_ARTIST_TYPE = @"artist";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_ALBUM_TYPE = @"album";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_TRACK_TYPE = @"track";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_TRACK_TITLE_SEARCH = @"track:";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_TRACK_ARTIST_SEARCH = @"artist:";
static const NSString *SPOTIFY_QUERY_URL_SEARCH_SEPARATOR = @" ";
static const NSInteger SPOTIFY_QUERY_URL_SEARCH_RESULTS_LIMIT = 50;

NSInteger trackCounter;
BOOL atLeastOneTrackFound;
SPTPlaylistSnapshot *playlistSnapshot;

@implementation SpotifyAPI

#pragma mark - Authentication

+(SPTSession*)getSavedSession {
    NSLog(@"[API]Getting saved session...");
    SPTAuth *auth = [SPTAuth defaultInstance];
    return [auth session];
}

+(void)saveSession:(SPTSession*)session {
    NSLog(@"[API]Saving session...");
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.session = session;
}

+(void)clearSession{
    NSLog(@"[API]Clearing session...");
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.session = nil;
}

+(void)renewSessionWithSuccess:(void (^)(SPTSession*))success
                    andFailure:(void (^)(NSError*)) failure
                   andProgress:(void (^)(void))progress {
    progress();
    NSLog(@"[API]Renewing session...");
    SPTAuth *auth = [SPTAuth defaultInstance];
    [auth renewSession:auth.session callback:^(NSError *error, SPTSession *session) {
        if (error || !session) {
            NSLog(@"[API]Error renewing session: %@", error);
            failure(error);
        } else {
            NSLog(@"[API]Session renewed");
            [self saveSession: session];
            success(session);
        }
    }];
}

+(void)getUserInfoWithSuccess:(void (^)(SPTUser *))success
                   andFailure:(void (^)(NSError *))failure
                  andProgress:(void (^)(void))progress{
    NSLog(@"[API]Getting user info");
    progress();
    SPTSession *session = [self getSavedSession];
    if (session && [session isValid]){
        NSLog(@"[API]Session valid");
        [SPTRequest userInformationForUserInSession:session callback:^(NSError *error, SPTUser *user) {
            if (!error){
                success(user);
            } else {
                failure(error);
            }
        }];
    } else {
        NSLog(@"[API]Session invalid");
        failure(nil);
    }
}

+(void)logoutWithSuccess:(void (^)(void))success
              andFailure:(void (^)(NSError*))failure {
    NSLog(@"[API]Logging out...");
    [self clearSession];
    success();
}

+(void)getArtistImageWithImageURL:(NSString*)imageURL
               AndNumberOfRetries:(NSInteger)numberOfRetries
                      WithSuccess:(void (^)(UIImageView*))success
                       andFailure:(void (^)(NSError*))failure {
    
    if (imageURL){
        UIImageView *imageView = [UIImageView new];
        [imageView setImageWithURL:[NSURL URLWithString: imageURL]];
        success(imageView);
    }
}

#pragma mark - Artist searching

+(void)findArtist:(NSString *)artistQuery
            withPage:(NSInteger)page
   AndNumberOfRetries:(NSInteger)numberOfRetries
    AndWithSuccess:(void (^)(NSData *artists))success
        andFailure:(void (^)(NSError *))failure {

    NSInteger offset = page * SPOTIFY_QUERY_URL_SEARCH_RESULTS_LIMIT;
    NSURL *url = [self prepareStringToSpotifyURL: [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",
                                                    SPOTIFY_QUERY_URL_BASE,
                                                    artistQuery,
                                                    SPOTIFY_QUERY_URL_OFFSET,
                                                    [NSString stringWithFormat:@"%ld", (long)offset],
                                                    SPOTIFY_QUERY_URL_LIMIT,
                                                    [NSString stringWithFormat:@"%ld", (long)SPOTIFY_QUERY_URL_SEARCH_RESULTS_LIMIT],
                                                    SPOTIFY_QUERY_URL_SEARCH_TYPE,
                                                    @"artist"]];
    NSLog(@"%@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL: url];
    
    NSHTTPURLResponse * response = nil;
    NSError *error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    BOOL requestSuccess = !error && response.statusCode == 200;
    if (requestSuccess){
        success(data);
    } else {
        if (numberOfRetries <= 0){
            failure(error);
        } else {
            NSLog(@"Retrying... %ld retries left. ", (long)numberOfRetries);
            [self findArtist: artistQuery withPage:page AndNumberOfRetries:numberOfRetries - 1 AndWithSuccess:success andFailure:failure];
        }
    }
}

#pragma mark - Track searching

+(void)findTrackWithSongTitle:(NSString*)songTitle
                andSongArtist:(NSString*)artist
           AndNumberOfRetries:(NSInteger)numberOfRetries
               AndWithSuccess:(void (^)(NSData *artists))success
                   andFailure:(void (^)(NSError *))failure {
    
    NSURL *url = [self prepareStringToSpotifyURL: [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",
                                                   SPOTIFY_QUERY_URL_BASE,
                                                   SPOTIFY_QUERY_URL_SEARCH_TRACK_TITLE_SEARCH,
                                                   songTitle,
                                                   SPOTIFY_QUERY_URL_SEARCH_SEPARATOR,
                                                   SPOTIFY_QUERY_URL_SEARCH_TRACK_ARTIST_SEARCH,
                                                   artist,
                                                   SPOTIFY_QUERY_URL_SEARCH_TYPE,
                                                   SPOTIFY_QUERY_URL_SEARCH_TRACK_TYPE]];
    NSLog(@"%@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL: url];
    
    NSHTTPURLResponse * response = nil;
    NSError *error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    BOOL requestSuccess = !error && response.statusCode == 200;
    if (requestSuccess){
        success(data);
    } else {
        if (numberOfRetries <=0){
            failure(error);
        } else {
            NSLog(@"Retrying... %ld retries left. ", (long)numberOfRetries);
            [self findTrackWithSongTitle:songTitle andSongArtist:artist AndNumberOfRetries:numberOfRetries - 1 AndWithSuccess:success andFailure:failure];
        }
    }
}

// Prepare URL string for UTF8 encoding
+ (NSURL*) prepareStringToSpotifyURL:(NSString *)inputString {
    NSString *escapedString = [inputString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString: escapedString];
}

+(void)createSpotifyTracksWithSpotifyURIs:(NSArray*) spotifyURIs
                              WithSuccess:(void (^)(NSArray *spotifyTracks))success
                               andFailure:(void (^)(NSError *))failure {
    
    SPTSession *session = [self getSavedSession];
    NSMutableArray *spotifyTracks = [NSMutableArray array];
    atLeastOneTrackFound = NO;
    [self getSpotifyTracksWithSpotifyURIs:spotifyURIs
                        WithSpotifyTracks:spotifyTracks
                              WithSession:session
                              WithSuccess:^(NSArray *spotifyTracks){
        success(spotifyTracks);
    } andFailure:^(NSError *error){
        failure(error);
    }];
}

+(void)getSpotifyTracksWithSpotifyURIs:(NSArray*)spotifyURIs
                     WithSpotifyTracks:(NSMutableArray*)spotifyTracks
                           WithSession:(SPTSession*)session
                           WithSuccess:(void (^)(NSArray *spotifyTracks))success
                            andFailure:(void (^)(NSError *))failure {
    
    if (spotifyURIs.count == 0){
        NSLog(@"End of the playlist creation");
        if (atLeastOneTrackFound){
            NSLog(@"At least one track found");
            success(spotifyTracks);
        } else {
            NSLog(@"No tracks found");
            failure(nil);
        }
        return;
    }
    
    NSMutableArray *mutableSpotifyURIs = [spotifyURIs mutableCopy];
    NSString *spotifyURI = [mutableSpotifyURIs firstObject];
    [mutableSpotifyURIs removeObject: spotifyURI];
    
    [SPTTrack trackWithURI:[NSURL URLWithString: spotifyURI]
                   session:session
                  callback:^(NSError *error, id object){
                      
                      // Track found
                      if (!error){
                          [spotifyTracks addObject: object];
                          atLeastOneTrackFound = YES;
                      } else {
                          NSLog(@"Track search error");
                      }
                      [self getSpotifyTracksWithSpotifyURIs:mutableSpotifyURIs
                                          WithSpotifyTracks:spotifyTracks
                                                WithSession:session
                                                WithSuccess:success
                                                 andFailure:failure];
                  }];
}

#pragma mark - Playlist creation

+(void)createPlaylistWithTracks:(NSArray *)tracks
               WithPlaylistName:(NSString*)playlistName
                    WithSuccess:(void (^)(SPTPlaylistSnapshot*))success
                     andFailure:(void (^)(NSError *))failure {
    
    BOOL publicFlag = YES;
    
    SPTSession *session = [self getSavedSession];
    
    [SpotifyAPI createSpotifyTracksWithSpotifyURIs:tracks WithSuccess:^(NSArray *spotifyTracks){
        SPTPlaylistList *playlistList = [[SPTPlaylistList alloc] init];
        [playlistList createPlaylistWithName:playlistName
                              publicFlag:publicFlag
                                 session:session
                                callback:^(NSError *error, SPTPlaylistSnapshot *playlist){
                                    
                                    if (!error){
                                        playlistSnapshot = playlist;
                                        [playlist addTracksToPlaylist:spotifyTracks
                                                          withSession:session
                                                             callback:^(NSError *error){
                                                                 if (!error){
                                                                     success(playlistSnapshot);
                                                                 } else {
                                                                     failure(error);
                                                                 }
                                                             }];
                                    } else {
                                        NSLog(@"Error");
                                        failure(error);
                                    }
                                }];
    } andFailure:^(NSError *error){
        failure(error);
    }];
}

@end
