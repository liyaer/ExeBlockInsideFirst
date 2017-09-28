//
//  ViewController.m
//  ExeBlockInsideFirst
//
//  Created by 杜文亮 on 2017/9/28.
//  Copyright © 2017年 杜文亮. All rights reserved.
//

#import "ViewController.h"


typedef void(^dwlBlock)();


@interface ViewController ()

@end

@implementation ViewController

-(void)testBlock:(dwlBlock)block
{
    block();
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"查看主线程ID号");
    
    [self scene];//出现问题的场景示例
    
    /*
     *   原理：信号量机制通过阻塞线程来实现。
     *   两个示例Demo都是在子线程，不能在主线程使用，因为会阻塞主线程，程序就会卡住不动了
     */
    [self demoOne];
}

-(void)scene
{
    __block NSString * string = @"LJ";
    [self testBlock:^
     {
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^//模拟一个耗时的操作
         {
             string = @"HR";
         });
     }];
    NSLog(@"string=%@",string);
}

//自定义的block示例 demoOne
-(void)demoOne
{
    __block NSString * string = @"LJ";
    //创建一个全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    //创建一个信号量（值为0）
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(queue, ^
   {
       [NSThread isMainThread] ? NSLog(@"是主线程") : NSLog(@"是zizi线程");
       
       [self testBlock:^
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^//模拟一个耗时的操作
            {
                string = @"HR";
                //信号量加1
                dispatch_semaphore_signal(semaphore);
            });
        }];
       //信号量减1，如果>=0，则向下执行，否则等待
       dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
       NSLog(@"string=%@",string);
   });
}

//系统的alter-block示例 demoTwo
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    __block BOOL isOK = YES;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(0, 0), ^
   {
       [NSThread isMainThread] ? NSLog(@"是主线程") : NSLog(@"是zizi线程");
       
       UIAlertController *alter = [UIAlertController alertControllerWithTitle:@"shaiba" message:@"sdfsadfsdfsdf" preferredStyle:UIAlertControllerStyleAlert];
       [alter addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
     {
         isOK = NO;
         dispatch_semaphore_signal(semaphore);
     }]];
       [self presentViewController:alter animated:YES completion:nil];
       
       dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
       if (!isOK)
       {
           NSLog(@"生效！");
       }
       else
       {
           NSLog(@"wu xiao !!!!!");
       }
   });
}



@end
