//
//  LineButton.m
//  OurGood
//
//  Created by Eric Mitchell on 12/30/15.
//  Copyright © 2015 OurGood. All rights reserved.
//

#import "LineButton.h"

@interface LineButton()

@property (nonatomic) BOOL lastHighlighted;

@end

@implementation LineButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        
        UIView* bottomLeftH = [[UIView alloc] init];
        UIView* bottomLeftV = [[UIView alloc] init];
        
        UIView* topLeftH = [[UIView alloc] init];
        UIView* topLeftV = [[UIView alloc] init];
        
        UIView* bottomRightH = [[UIView alloc] init];
        UIView* bottomRightV = [[UIView alloc] init];
        
        UIView* topRightH = [[UIView alloc] init];
        UIView* topRightV = [[UIView alloc] init];
        
        CGSize size = CGSizeMake(1.f, 6.f);
        
        NSArray* views = @[bottomLeftH, bottomRightH, topLeftH, topRightH, bottomLeftV, bottomRightV, topLeftV, topRightV];
        
        NSDictionary* bindings = NSDictionaryOfVariableBindings(bottomLeftH, bottomLeftV, bottomRightH, bottomRightV, topLeftH, topLeftV, topRightH, topRightV);
        NSDictionary* metrics = @{@"width": @(size.width), @"length": @(size.height)};
        
        [self addSubview:bottomLeftH];
        [self addSubview:bottomLeftV];
        
        [self addSubview:bottomRightH];
        [self addSubview:bottomRightV];
        
        [self addSubview:topLeftH];
        [self addSubview:topLeftV];
        
        [self addSubview:topRightH];
        [self addSubview:topRightV];
        
        NSMutableArray* constraints =
        [NSMutableArray arrayWithArray:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"H:|[bottomLeftV(width)]-(>=0)-[bottomRightV(width)]|"
                                        options:0
                                        metrics:metrics
                                        views:bindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|[topLeftV(width)]-(>=0)-[topRightV(width)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|[topLeftH(width)]-(>=0)-[bottomLeftH(width)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|[topRightH(width)]-(>=0)-[bottomRightH(width)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        /********************/
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|[topLeftV(length)]-(>=0)-[bottomLeftV(length)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|[bottomLeftH(length)]-(>=0)-[bottomRightH(length)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|[topRightV(length)]-(>=0)-[bottomRightV(length)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|[topLeftH(length)]-(>=0)-[topRightH(length)]|"
                                          options:0
                                          metrics:metrics
                                          views:bindings]];
        
        [self addConstraints:constraints];
        
        for (UIView* view in views) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.tag = 1;
            
            view.backgroundColor = self.tintColor;
        }
    }
    return self;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    
    for (UIView* view in self.subviews) {
        if (view.tag == 1) {
            if ([view.backgroundColor isEqual:self.tintColor]) {
                view.backgroundColor = [UIColor grayColor];
            } else {
                view.backgroundColor = self.tintColor;
            }
        }
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    for (UIView* view in self.subviews) {
        if (view.tag == 1) {
            view.backgroundColor = tintColor;
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (_lastHighlighted != highlighted) {
        if (highlighted) {
                for (UIView* view in self.subviews) {
                    if (view.tag == 1) {
                        view.alpha = 0.f;
                    }
                }
        } else {
            [UIView animateWithDuration:.2f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                for (UIView* view in self.subviews) {
                    if (view.tag == 1) {
                        view.alpha = 1.f;
                    }
                }
            } completion:nil];
        }
    }
    
    _lastHighlighted = highlighted;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
