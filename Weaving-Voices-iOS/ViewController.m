//
//  ViewController.m
//  Weaving-Voices-iOS
//
//  Created by Panos Pandis on 5/11/14.
//  Copyright (c) 2014 Panos Pandis. All rights reserved.
//

#import "ViewController.h"

NSString *pathToAudioFile;

@interface ViewController () {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
}


@end

@implementation ViewController
@synthesize stopButton, playButton, recordPauseButton, uploadButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Disable Stop/Play button when application launches
    [stopButton setEnabled:NO];
    [playButton setEnabled:NO];
    [uploadButton setEnabled:NO];
    
    //UIDevice *device = [UIDevice currentDevice];
    
    //NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    //NSString  *timestamp = [NSString stringWithFormat:@"%f",[[NSDate new] timeIntervalSince1970] * 1000];
    //NSString *fileName = [NSString stringWithFormat:@"%@%@%@", timestamp, currentDeviceId, @".aac"];
    NSString *fileName = [NSString stringWithFormat:@"recording.aiff"];
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               fileName,
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];

    pathToAudioFile = outputFileURL.path;
    //pathToAudioFile = pathComponents[0];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //[recordSetting setValue:[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordPauseTapped:(id)sender {
    // Stop the audio player before recording
    if (player.playing) {
        [player stop];
    }
    
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        [recordPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        
    } else {
        
        // Pause recording
        [recorder pause];
        [recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    }
    
    [stopButton setEnabled:YES];
    [playButton setEnabled:NO];
}

- (IBAction)stopTapped:(id)sender {
    [recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}

- (IBAction)playTapped:(id)sender {
    if (!recorder.recording){
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player setDelegate:self];
        [player play];
    }
}

- (IBAction)uploadTapped:(id)sender{
//    NSString *emailAddress = _emailTextField.text;
    if (![self NSStringIsValidEmail:_emailTextField.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Email Address"
                                                        message: @"Please provide a valid email address!"
                                                       delegate: nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }else{
        NSString* path = pathToAudioFile;
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        
        NSString *urlString = @"http://83.212.97.2/upload.php";
        NSMutableURLRequest *request= [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        NSString  *timestamp = [NSString stringWithFormat:@"%f",[[NSDate new] timeIntervalSince1970] * 1000];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data;name=\"uploaded_file\"; filename=\"%@/%@-%@.aiff\"\r\n", pathToAudioFile, _emailTextField.text, timestamp]dataUsingEncoding:NSUTF8StringEncoding]];
        //"uploadedfile" should be substituted for whatever variable the backend script expects the file variable to be
        [postbody appendData:[@"Content-Type: application/octet-streamrnrn" dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:postbody];
        
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        NSLog(@"returned string: %@", returnString); //Just for display purposes
    }
}

#pragma mark - AVAudioRecorderDelegate

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    [stopButton setEnabled:NO];
    [playButton setEnabled:YES];
    [uploadButton setEnabled:YES];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Done"
                                                    message: @"Finish playing the recording!"
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)backgroundTapped:(id)sender{
    [self.view endEditing:YES];
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
@end
