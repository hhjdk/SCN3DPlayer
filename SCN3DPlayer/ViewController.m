//
//  ViewController.m
//  SCN3DPlayer
//
//  Created by 俞涛涛 on 16/11/11.
//  Copyright © 2016年 俞涛涛. All rights reserved.
//

#import "ViewController.h"

#import "HelloViewController.h"

@interface ViewController (){


}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)btnClick:(UIButton *)sender {
//     [self performSegueWithIdentifier:@"segue1" sender:self];
    HelloViewController * hVC = [[HelloViewController alloc]init];
    [self presentViewController:hVC animated:YES completion:nil];

}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segue1"]) {
//        HelloViewController * helloVc = segue.destinationViewController;


        
       
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
