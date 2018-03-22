##Object-C中的load和initialize方法
> NSObject类中有两个特殊方法：**load**、**initialize**，这两个方法有什么区别呢？如何使用呢？调用场景是什么？

本文依赖的代码：**SuperLoad类**

```
#import "SuperLoad.h"

@implementation SuperLoad

+(void)load {
    NSLog(@"我是 superLoad，我被触发了");
}

+(void)initialize {
    NSLog(@"我是 superInitialize，我被触发了");
}

@end
```
**SubLoad类**

```
#import "SubLoad.h"

@implementation SubLoad

+(void)load {
    NSLog(@"我是 SubLoad，我被触发了");
}

+(void)initialize {
    NSLog(@"我是 SubInitialize，我被触发了");
}

@end
```
**main函数**

```
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSLog(@"main函数调用");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

本文的[demo地址](https://github.com/haogaoming123/load-initialize_difference.git)、本文的[博客地址](https://www.jianshu.com/p/c96788c91ca0)

##1、区别

###1.1 load方法和initialize调用时机

运行代码之后，可见控制台打印为：

```
2018-03-20 10:43:47.923316+0800 我是 superLoad，我被触发了
2018-03-20 10:43:51.014019+0800 我是 SubLoad，我被触发了
2018-03-20 10:44:11.318210+0800 main函数调用
2018-03-20 10:44:11.393657+0800 我是 superInitialize，我被触发了
2018-03-20 10:44:13.431475+0800 我是 SubInitialize，我被触发了
```
由此可见，**load方法是在main函数之前调用，initialize函数是在main函数之外调用。**

###1.2 load方法和initialize方法在继承关系中的区别

将SuperLoad类中的load方法注释，SubLoad类中的initialize方法注释，运行代码，可见控制台打印：

```
2018-03-20 11:29:24.933753+0800 我是 SubLoad，我被触发了
2018-03-20 11:29:24.934582+0800 main函数调用
2018-03-20 11:29:25.011858+0800 我是 superInitialize，我被触发了
2018-03-20 11:29:25.011961+0800 我是 superInitialize，我被触发了
```
将SuperLoad类中的load方法打开，SubLoad类中的load方法注释，运行代码，可见控制台打印：

```
2018-03-20 11:29:24.933753+0800 我是 superLoad，我被触发了
2018-03-20 11:29:24.934582+0800 main函数调用
2018-03-20 11:29:25.011858+0800 我是 superInitialize，我被触发了
2018-03-20 11:29:25.011961+0800 我是 superInitialize，我被触发了
```
由此可见，**load和initialize方法都不用显示的调用父类的方法而是自动调用，即使子类没有initialize方法也会调用父类的方法，而load方法则不会调用父类。**

###1.3 各自使用的场景
**load方法通常用来进行Method Swizzle，initialize方法一般用于初始化全局变量或静态变量**

###1.4 当添加categroy时，load和initialize的调用机制是怎样的
添加如下代码

```
@implementation SuperLoad(Category)
+(void)load {
    NSLog(@"我是 CategoryLoad，我被调用了");
}

+(void)initialize {
    NSLog(@"我是 CategoryInitialize，我被触发了");
}
@end
```
控制台打印：

```
2018-03-21 15:04:33.234859+0800 我是 superLoad，我被触发了
2018-03-21 15:04:33.235951+0800 我是 SubLoad，我被触发了
2018-03-21 15:04:33.236106+0800 我是 CategoryLoad，我被调用了
2018-03-21 15:04:33.236282+0800 main函数调用
2018-03-21 15:04:33.336564+0800 我是 CategoryInitialize，我被触发了
2018-03-21 15:04:33.336682+0800 我是 SubInitialize，我被触发了
```

大家可以看到，**load的调用顺序为：父类load ---> 子类load ---> Category的load；而Category的initialize直接就覆盖了父类的initialize。**


##2、结合runtime源码来理解一下为什么会造成上述的区别和不同

###2.1 load方法
首先打印一下load方法的调用栈：
![load调用栈.png](https://upload-images.jianshu.io/upload_images/3488832-182eb2cc28a22d79.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

**_dyld_start ---> ::objc_init() ---> _dyld_objc_notify_register ---> ::load_images() ---> call_load_methods() ---> call_class_loads() ---> +[NSObject load]**

这里我们发现调用栈是从_dyld_start开始的，这里的dyld叫做APPle动态连接器，在程序启动后当系统做好了一些初始化的准备，会将后面的事甩锅给dyld负责，dyld会将程序依赖动态库加载进内存初始化，但他干不来所有事，所以他就初始化了runtime小弟来帮他将所有即将使用的库的二进制数据进行解析并初始化里面类的结构。

_objc_init()函数为runtime的初始化方法，下面我们在[runtime源码](https://codeload.github.com/RetVal/objc-runtime/zip/master)中查看一下，load的调用方法。

![runtime初始化.png](https://upload-images.jianshu.io/upload_images/3488832-9b259202423c4a4d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

map_images 主要是在image加载进内容后对其二进制内容进行解析，初始化里面的类的结构等。
load_images 主要是调用call_load_methods。按照继承层次依次调用Class的+load方法然后再是Category的+load方法。

我们来看load_images方法的具体实现:

**load_images**

![load_images.png](https://upload-images.jianshu.io/upload_images/3488832-805cb011078cb353.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

在这里，我们发现两个重要**`prepare_load_methods`**和**`call_load_methods`**，通过中间的一段注释`// Discover load methods`知道，中括号里边的**`prepare_load_methods`**方法是进行加载APP代码中工程师重写的load方法。而**`call_load_methods`**方法是加载系统中的load方法。接下来，咱们看一下**`prepare_load_methods`**这个方法的具体实现来验证一下观点。

**prepare_load_methods**

![prepare_load_methods.png](https://upload-images.jianshu.io/upload_images/3488832-223e4c81f60651a9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

在这里我们看出，class和category的处理load方法被分开处理了，先通过**`schedule_class_load`**将需要执行load的class添加到一个全局列表`loadable_classes`；然后通过**`add_category_to_loadable_list`**方法，将需要执行load的category添加到另一个全局列表`loadable_categories`。这也就是为什么Category添加了load()方法之后，会产生**父类load ---> 子类load ---> Category的load这样的一个调用顺序。**

**schedule_class_load**

![schedule_class_load.png](https://upload-images.jianshu.io/upload_images/3488832-5165a079690a7ce0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

这里可以看出，**schedule_class_load方法会递归处理父类，确保父类先被添加到全局列表`loadable_classes`中。**

**add_class_to_loadable_list**

![add_class_to_loadable_list.png](https://upload-images.jianshu.io/upload_images/3488832-39d2ec04b6d53874.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

**loadable_classes、loadable_categories全局列表定义**
![loadable_classes+loadable_categories.png](https://upload-images.jianshu.io/upload_images/3488832-2f58b4bec349c8c0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)


这里可以看出，**处理load方法时，runtime直接获取到method的指针，然后将objc_class和method指针(IMP)添加到全局列表`loadable_classes`中，而category同样也是这种操作**

现在，在回到`call_load_methods`方法中，

**call_load_methods**

![call_load_methods.png](https://upload-images.jianshu.io/upload_images/3488832-351cbbb638afa41e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

**call_class_loads** 具体执行函数实现

![call_class_loads.png](https://upload-images.jianshu.io/upload_images/3488832-574b3c5d1c0b93f0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

这里，我们可以看到，load方法是直接执行的函数指针，而没有走objc_msgSend消息转发那一套流程，由于没有消息转发机制，所以，子类没有实现load方法，父类实现了load方法，调用的时候，也不会调用父类。

那么大家就猜想了，initialize是在类初始化的时候才被调用，是不是它走了消息转发机制呢？

###2.2 initialize方法

首先打印一下initialize的调用栈：
![initialize.png](https://upload-images.jianshu.io/upload_images/3488832-4973f8ee9385a171.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

通过查看调用栈可知，initialize方法确实是走了消息转发机制,因为它的调用方法里边有`_objc_msgSend_uncached`，有了以上分析load代码的经验，我们来分析一下initialize方法。

首先查看`_objc_mesageSend_uncached`
![_objc_messageSend_uncached.png](https://upload-images.jianshu.io/upload_images/3488832-16700486e473cd84.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)

这看起来貌似是一些汇编指令了，调用了`MethodTableLookup`的指令，然后我们继续向上看`_class_lookupMethodAndLoadCache3`
![_class_lookupMethodAndLoadCache3.png](https://upload-images.jianshu.io/upload_images/3488832-6970b1345122c73c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/520)


由于**`lookUpImpOrForward`**代码量巨大，所以这里粘贴一部分

```
IMP lookUpImpOrForward(Class cls, SEL sel, id inst, 
                       bool initialize, bool cache, bool resolver)
{
    IMP imp = nil;
    bool triedResolver = NO;

    runtimeLock.assertUnlocked();

    // Optimistic cache lookup
    if (cache) {
        imp = cache_getImp(cls, sel);
        if (imp) return imp;
    }

    runtimeLock.read();

	 //重要方法：_class_initialize (_class_getNonMetaClass(cls, inst))
    if (initialize  &&  !cls->isInitialized()) {
        runtimeLock.unlockRead();
        _class_initialize (_class_getNonMetaClass(cls, inst));
        runtimeLock.read();
        // If sel == initialize, _class_initialize will send +initialize and 
        // then the messenger will send +initialize again after this 
        // procedure finishes. Of course, if this is not being called 
        // from the messenger then it won't happen. 2778172
    }
}
```
这里我们看到，有一个重要方法`_class_initialize`，这个就是实现initialize的核心代码。

**`_class_initialize`** 删除一些代码：

```
void _class_initialize(Class cls)
{
    assert(!cls->isMetaClass());

    Class supercls;
    bool reallyInitialize = NO;
	
	//这里可以看到，也是递归循环superclass
    supercls = cls->superclass;
    if (supercls  &&  !supercls->isInitialized()) {
        _class_initialize(supercls);
    }
    
    // Try to atomically set CLS_INITIALIZING.
    {
        monitor_locker_t lock(classInitLock);
        if (!cls->isInitialized() && !cls->isInitializing()) {
            cls->setInitializing();
            reallyInitialize = YES;
        }
    }
    
    if (reallyInitialize) {
#if __OBJC2__
        @try
#endif
        {
            //重要方法
            callInitialize(cls);

            if (PrintInitializing) {
                _objc_inform("INITIALIZE: thread %p: finished +[%s initialize]",
                             pthread_self(), cls->nameForLogging());
            }
        }
#if __OBJC2__
        @catch (...) {
            if (PrintInitializing) {
                _objc_inform("INITIALIZE: thread %p: +[%s initialize] "
                             "threw an exception",
                             pthread_self(), cls->nameForLogging());
            }
            @throw;
        }
        @finally
#endif
        {
            // Done initializing.
            lockAndFinishInitializing(cls, supercls);
        }
        return;
    }
}
```
终于到了结尾了，通过上述代码，我们发现 initialize 也是取出父类递归执行，确保父类的方法先被执行到。然而最关键的方法，就是：**`callInitialize`**

```
void callInitialize(Class cls)
{
    ((void(*)(Class, SEL))objc_msgSend)(cls, SEL_initialize);
    asm("");
}
```

这里我们发现 initialize 最终是通过 objc_msgSend 来执行的，即initialize 是会经过一系列方法查找来执行的。

至于接下来的objc_msgSend消息转发之后的流程，会在以后的篇幅介绍。

