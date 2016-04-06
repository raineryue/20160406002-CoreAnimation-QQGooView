//
//  GooButton.m
//  20160406002-CoreAnimation-QQGooView
//
//  Created by Rainer on 16/4/6.
//  Copyright © 2016年 Rainer. All rights reserved.
//

#import "GooButton.h"

#define kButtonWH self.bounds.size.width
#define kMaxDistance 80

@interface GooButton ()

@property (nonatomic, weak) UIView *smallSircleView;
@property (nonatomic, weak) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) CGFloat smallOriginalRadius;

@end

@implementation GooButton

/**
 *  初始化
 */
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUIView];
    }
    
    return self;
}

/**
 *  xib加载
 */
- (void)awakeFromNib {
    [self setupUIView];
}

/**
 *  设置控件
 */
- (void)setupUIView {
    self.backgroundColor = [UIColor redColor];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    self.layer.cornerRadius = kButtonWH * 0.5;
    self.smallOriginalRadius = self.layer.cornerRadius;
    
    self.smallSircleView.bounds = self.bounds;
    self.smallSircleView.center = self.center;
    
    // 这里需要用手势滑动而不能使用touch事件，主要原因是为了防止按钮监听事件和touch事件冲突
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    
    [self addGestureRecognizer:panGestureRecognizer];
}

/**
 *  手指平移事件监听
 */
- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取偏移点
    CGPoint translationPoint = [panGestureRecognizer translationInView:self];
    
    // 设置按钮的偏移信息：修改偏移量不会修改center，如果不修改center是无法计算圆心距的
//    self.transform = CGAffineTransformTranslate(self.transform, translationPoint.x, translationPoint.y);
    
    CGPoint center = self.center;
    
    center.x += translationPoint.x;
    center.y += translationPoint.y;
    
    self.center = center;
    
    // 手势偏移复位
    [panGestureRecognizer setTranslation:CGPointZero inView:self];
    
    // 获取圆心距
    CGFloat circleCenterDistance = [self circleCenterDistanceWithSmallCircleCenterPoint:self.smallSircleView.center BigCircleCenterPoint:self.center];
    
    CGFloat smallRadius = self.smallOriginalRadius - circleCenterDistance / 10;
    
    self.smallSircleView.bounds = CGRectMake(0, 0, smallRadius * 2, smallRadius * 2);
    self.smallSircleView.layer.cornerRadius = smallRadius;
    
    // 绘制不规则矩形，不能通过绘图实现，因为绘图只能在当前控件上画，超出部分不会显示。
    // 两圆产生距离才需要绘制
    if (circleCenterDistance) {
        // 展示不规则矩形，通过不规则矩形路径生成一个图层
        self.shapeLayer.path = [self pathWithBigCircleView:self smallCircleView:self.smallSircleView].CGPath;
    }
    
    // 当圆心距离大于最大圆心距离
    if (circleCenterDistance > kMaxDistance) { // 可以拖出来
        // 隐藏小圆
        self.smallSircleView.hidden = YES;
        
        // 移除不规则的矩形
        [self.shapeLayer removeFromSuperlayer];
        self.shapeLayer = nil;
    } else if (circleCenterDistance > 0 && self.smallSircleView.hidden == NO){ // 有圆心距离，并且圆心距离不大，才需要展示
        // 展示不规则矩形，通过不规则矩形路径生成一个图层
        self.shapeLayer.path = [self pathWithBigCircleView:self smallCircleView:self.smallSircleView].CGPath;
    }
    
    // 当手势停止时的操作
    if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // 当圆心距离大于最大圆心距离
        if (circleCenterDistance > kMaxDistance) {
            // 展示gif动画
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
            NSMutableArray *arrM = [NSMutableArray array];
            
            for (int i = 1; i < 9; i++) {
                UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d",i]];
                [arrM addObject:image];
            }
            
            imageView.animationImages = arrM;
            imageView.animationRepeatCount = 1;
            imageView.animationDuration = 0.5;
            
            [imageView startAnimating];
            
            [self addSubview:imageView];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeFromSuperview];
            });
        } else {
            // 移除不规则矩形
            [self.shapeLayer removeFromSuperlayer];
            self.shapeLayer = nil;
            
            // 还原位置
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.2 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
                // 设置大圆中心点位置
                self.center = self.smallSircleView.center;
            } completion:^(BOOL finished) {
                // 显示小圆
                self.smallSircleView.hidden = NO;
            }];
        }
    }
}

/**
 *  计算大圆与小圆的圆心距（公式：开方(圆心距X的平方 ＋ 圆心距Y的平方)）
 */
- (CGFloat)circleCenterDistanceWithSmallCircleCenterPoint:(CGPoint)smallCircleCenterPoint BigCircleCenterPoint:(CGPoint)bigCircleCenterPoint {
    CGFloat offsetX = bigCircleCenterPoint.x - smallCircleCenterPoint.x;
    CGFloat offsetY = bigCircleCenterPoint.y - smallCircleCenterPoint.y;
    
    return sqrtf(offsetX * offsetX + offsetY * offsetY);
}

/**
 *  描述两圆之间一条矩形路径
 */
- (UIBezierPath *)pathWithBigCircleView:(UIView *)bigCircleView  smallCircleView:(UIView *)smallCircleView {
    CGPoint bigCenter = bigCircleView.center;
    CGFloat x2 = bigCenter.x;
    CGFloat y2 = bigCenter.y;
    CGFloat r2 = bigCircleView.bounds.size.width / 2;
    
    CGPoint smallCenter = smallCircleView.center;
    CGFloat x1 = smallCenter.x;
    CGFloat y1 = smallCenter.y;
    CGFloat r1 = smallCircleView.bounds.size.width / 2;
    
    // 获取圆心距离
    CGFloat d = [self circleCenterDistanceWithSmallCircleCenterPoint:bigCenter BigCircleCenterPoint:smallCenter];
    
    CGFloat sinθ = (x2 - x1) / d;
    
    CGFloat cosθ = (y2 - y1) / d;
    
    // 坐标系基于父控件
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ , y1 + r1 * sinθ);
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ , y1 - r1 * sinθ);
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ , y2 - r2 * sinθ);
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ , y2 + r2 * sinθ);
    CGPoint pointO = CGPointMake(pointA.x + d / 2 * sinθ , pointA.y + d / 2 * cosθ);
    CGPoint pointP =  CGPointMake(pointB.x + d / 2 * sinθ , pointB.y + d / 2 * cosθ);
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // A
    [bezierPath moveToPoint:pointA];
    
    // AB
    [bezierPath addLineToPoint:pointB];
    
    // 绘制BC曲线
    [bezierPath addQuadCurveToPoint:pointC controlPoint:pointP];
    
    // CD
    [bezierPath addLineToPoint:pointD];
    
    // 绘制DA曲线
    [bezierPath addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return bezierPath;
}

/**
 *  懒加载小圆
 */
- (UIView *)smallSircleView {
    if (nil == _smallSircleView) {
        UIView *smallSircleView = [[UIView alloc] init];
        
        smallSircleView.layer.cornerRadius = kButtonWH * 0.5;
        smallSircleView.backgroundColor = self.backgroundColor;
        
        _smallSircleView = smallSircleView;
        
        [self.superview insertSubview:self.smallSircleView belowSubview:self];
    }
    
    return _smallSircleView;
}

/**
 *  懒加载不规则图层
 */
- (CAShapeLayer *)shapeLayer {
    if (nil == _shapeLayer) {
        // 展示不规则矩形，通过不规则矩形路径生成一个图层
        CAShapeLayer *layer = [CAShapeLayer layer];
        
        layer.fillColor = self.backgroundColor.CGColor;
        _shapeLayer = layer;
        
        [self.superview.layer insertSublayer:layer below:self.layer];
    }
    
    return _shapeLayer;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
