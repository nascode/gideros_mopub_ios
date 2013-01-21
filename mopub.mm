/*
 
 This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
 (C) 2013 Nightspade
 
 */

#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"

#include "MPAdView.h"
#include "MPInterstitialAdController.h"

// some Lua helper functions
#ifndef abs_index
#define abs_index(L, i) ((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : lua_gettop(L) + (i) + 1)
#endif

static void luaL_newweaktable(lua_State *L, const char *mode)
{
	lua_newtable(L);			// create table for instance list
	lua_pushstring(L, mode);
	lua_setfield(L, -2, "__mode");	  // set as weak-value table
	lua_pushvalue(L, -1);             // duplicate table
	lua_setmetatable(L, -2);          // set itself as metatable
}

static void luaL_rawgetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_rawget(L, idx);
}

static void luaL_rawsetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_insert(L, -2);
	lua_rawset(L, idx);
}

enum
{
	GMOPUB_AD_WILL_LOAD_EVENT,
	GMOPUB_AD_LOADED_EVENT,
	GMOPUB_AD_FAILED_EVENT,
	GMOPUB_AD_CLOSED_EVENT,
	GMOPUB_INTERSTITIAL_LOADED_EVENT,
	GMOPUB_INTERSTITIAL_FAILED_EVENT,
	GMOPUB_INTERSTITIAL_CLOSED_EVENT,
    GMOPUB_CUSTOM_EVENT,
};

static const char *TOP = "top";
static const char *BOTTOM = "bottom";

static const int kTOP = 0;
static const int kBOTTOM = 1;

static const char *AD_WILL_LOAD = "adWillLoad";
static const char *AD_LOADED = "adLoaded";
static const char *AD_FAILED = "adFailed";
static const char *AD_CLOSED = "adClosed";
static const char *INTERSTITIAL_LOADED = "interstitialLoaded";
static const char *INTERSTITIAL_FAILED = "interstitialFailed";
static const char *INTERSTITIAL_CLOSED = "interstitialClosed";
static const char *CUSTOM_EVENT = "customEvent";

static char keyWeak = ' ';

class MoPub;

@interface MoPubDelegate : NSObject<MPAdViewDelegate, MPInterstitialAdControllerDelegate>
{
}

- (id) initWithBanner:(MoPub*)banner;

@property (nonatomic, assign) MoPub *banner;

@end

class MoPub : public GEventDispatcherProxy
{
public:
	MoPub(lua_State *L) : L(L), view_(nil), interstitial_(nil), alignment_(kBOTTOM)
	{
        delegate_ = [[MoPubDelegate alloc] initWithBanner:this];
    }
    
	~MoPub()
	{
        [delegate_ release];
        
        view_.delegate = nil;
        [view_ removeFromSuperview];
        [view_ release];
        
        interstitial_.delegate = nil;
	}
    
	void showBanner(const char* adUnitId)
	{
        if (!view_){
            view_ = [[MPAdView alloc] initWithAdUnitId:[NSString stringWithUTF8String:adUnitId] size:MOPUB_BANNER_SIZE];
            view_.delegate = delegate_;
            // view_.animationType = MPAdAnimationTypeCurlUp;
        
            dispatchEvent(GMOPUB_AD_WILL_LOAD_EVENT, NULL);
            [view_ loadAd];
        }
	}
    
	void hideBanner()
	{
		[view_ removeFromSuperview];
        [view_ release];
        view_ = nil;
	}
    
	const char* getAlignment()
	{
        if (alignment_ == kTOP) {
            return TOP;
        } else {
            return BOTTOM;
        }
	}
    
	void setAlignment(const char* alignment)
	{
        if (0 == strcmp(alignment, TOP)) {
            alignment_ = kTOP;
        } else if (0 == strcmp(alignment, BOTTOM)) {
            alignment_ = kBOTTOM;
        }
        
		if (view_.superview != nil)
			updateFramePosition();
	}
    
	bool getAutoRefresh()
	{
		return view_.ignoresAutorefresh;
	}
    
	void setAutoRefresh(BOOL enabled)
	{
		view_.ignoresAutorefresh = enabled;
	}
    
	void loadInterstitial(const char* adUnitId)
	{
        interstitial_ = [MPInterstitialAdController interstitialAdControllerForAdUnitId:[NSString stringWithUTF8String:adUnitId]];
        interstitial_.delegate = delegate_;
		[interstitial_ loadAd];
	}
    
	void showInterstitial()
	{
        [interstitial_ showFromViewController:g_getRootViewController()];
	}
    
    void customEventDidLoadAd()
    {
        [view_ customEventDidLoadAd];
    }
    
    void customEventDidFailToLoadAd()
    {
        [view_ customEventDidFailToLoadAd];
    }
    
    void customEventActionDidEnd()
    {
        [view_ customEventActionDidEnd];
    }
    
    void customEventActionWillBegin()
    {
        [view_ customEventActionWillBegin];
    }
    
	void dispatchEvent(int type, void *event)
	{
		luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
		luaL_rawgetptr(L, -1, this);
        
		if (lua_isnil(L, -1))
		{
			lua_pop(L, 2);
			return;
		}
        
		lua_getfield(L, -1, "dispatchEvent");
        
		lua_pushvalue(L, -2);
        
		lua_getglobal(L, "Event");
		lua_getfield(L, -1, "new");
		lua_remove(L, -2);
        
		switch (type)
		{
            case GMOPUB_AD_WILL_LOAD_EVENT:
                lua_pushstring(L, AD_WILL_LOAD);
                break;
            case GMOPUB_AD_LOADED_EVENT:
                lua_pushstring(L, AD_LOADED);
                break;
            case GMOPUB_AD_FAILED_EVENT:
                lua_pushstring(L, AD_FAILED);
                break;
            case GMOPUB_AD_CLOSED_EVENT:
                lua_pushstring(L, AD_CLOSED);
                break;
            case GMOPUB_INTERSTITIAL_LOADED_EVENT:
                lua_pushstring(L, INTERSTITIAL_LOADED);
                break;
            case GMOPUB_INTERSTITIAL_FAILED_EVENT:
                lua_pushstring(L, INTERSTITIAL_FAILED);
                break;
            case GMOPUB_INTERSTITIAL_CLOSED_EVENT:
                lua_pushstring(L, INTERSTITIAL_CLOSED);
                break;
            case GMOPUB_CUSTOM_EVENT:
                lua_pushstring(L, CUSTOM_EVENT);
                break;
		}
        
		lua_call(L, 1, 1);
        
        if (type == GMOPUB_CUSTOM_EVENT && event)
		{
			lua_pushstring(L, (char*)event);
			lua_setfield(L, -2, "name");
		}
        
		lua_call(L, 2, 0);
        
		lua_pop(L, 2);
	}
    
    void updateFramePosition()
	{   
		CGRect frame = view_.frame;
		if (alignment_ == kTOP)
		{
			frame.origin = CGPointMake(0, 0);
		}
		else
		{
			int height;
			CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGSize adSize =  [view_ adContentViewSize];
            
            if (UIInterfaceOrientationIsPortrait(g_getRootViewController().interfaceOrientation))
				height = screenRect.size.height;
			else
				height = screenRect.size.width;
            
            frame.origin = CGPointMake(0, height - adSize.height);
		}
		view_.frame = frame;
	}
    
private:
	lua_State *L;
    
    MoPubDelegate *delegate_;
    MPAdView *view_;
    MPInterstitialAdController *interstitial_;
    int alignment_;
};

@implementation MoPubDelegate

@synthesize banner = banner_;

- (id)initWithBanner:(MoPub *)banner
{
	if (self = [super init])
	{
        banner_ = banner;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [super dealloc];
}

- (UIViewController *)viewControllerForPresentingModalView
{
    return g_getRootViewController();
}

- (void)orientationDidChange:(NSNotification *)notification
{
    if (banner_)
        banner_->updateFramePosition();
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view;
{
    if (banner_)
        banner_->dispatchEvent(GMOPUB_AD_FAILED_EVENT, NULL);
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
    if (banner_)
    {
        if (!view.superview)
        {
            UIViewController *viewController = g_getRootViewController();
            [viewController.view addSubview:view];
        
            banner_->updateFramePosition();
        }
        banner_->dispatchEvent(GMOPUB_AD_LOADED_EVENT, NULL);
    }
}

- (void)didDismissModalViewForAd:(MPAdView *)view
{
    if (banner_)
        banner_->dispatchEvent(GMOPUB_AD_CLOSED_EVENT, NULL);
}

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial
{
    if (banner_)
        banner_->dispatchEvent(GMOPUB_INTERSTITIAL_LOADED_EVENT, NULL);
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial
{
    if (banner_)
        banner_->dispatchEvent(GMOPUB_INTERSTITIAL_FAILED_EVENT, NULL);
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial
{
    if (banner_)
        banner_->dispatchEvent(GMOPUB_INTERSTITIAL_CLOSED_EVENT, NULL);
}

// EXAMPLE OF CUSTOM EVENT
/*
- (void)greystripeBannerEvent:(MPAdView *)view;
{
    if (banner_)
        banner_->dispatchEvent(GMOPUB_CUSTOM_EVENT, (void *)"greystripeBannerEvent");
}
*/

@end

static int destruct(lua_State* L)
{
	void *ptr =*(void**)lua_touserdata(L, 1);
	GReferenced* object = static_cast<GReferenced*>(ptr);
	MoPub *mopub = static_cast<MoPub*>(object->proxy());
	mopub->unref();
    
	return 0;
}

static MoPub *getInstance(lua_State *L, int index)
{
	GReferenced *object = static_cast<GReferenced*>(g_getInstance(L, "MoPub", index));
	MoPub *mopub = static_cast<MoPub*>(object->proxy());
	return mopub;
}

static int showBanner(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	const char *adUnitId = lua_tostring(L, 2);
	mopub->showBanner(adUnitId);
	return 0;
}

static int hideBanner(lua_State *L)
{
    MoPub *mopub = getInstance(L, 1);
    mopub->hideBanner();
    return 0;
}

static int getAlignment(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	lua_pushstring(L, mopub->getAlignment());
	return 1;
}

static int setAlignment(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	const char *alignment = lua_tostring(L, 2);
	mopub->setAlignment(alignment);
	return 0;
}

static int getAutoRefresh(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	lua_pushboolean(L, mopub->getAutoRefresh());
	return 1;
}

static int setAutoRefresh(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	bool enabled = lua_toboolean(L, 2);
	mopub->setAutoRefresh(enabled);
	return 0;
}

static int loadInterstitial(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	const char *adUnitId = lua_tostring(L, 2);
	mopub->loadInterstitial(adUnitId);
	return 0;
}

static int showInterstitial(lua_State *L)
{
	MoPub *mopub = getInstance(L, 1);
	mopub->showInterstitial();
	return 0;
}

static int customEventDidLoadAd(lua_State *L)
{
    MoPub *mopub = getInstance(L, 1);
	mopub->customEventDidLoadAd();
	return 0;
}

static int customEventDidFailToLoadAd(lua_State *L)
{
    MoPub *mopub = getInstance(L, 1);
	mopub->customEventDidFailToLoadAd();
	return 0;
}

static int customEventActionWillBegin(lua_State *L)
{
    MoPub *mopub = getInstance(L, 1);
	mopub->customEventActionWillBegin();
	return 0;
}

static int customEventActionDidEnd(lua_State *L)
{
    MoPub *mopub = getInstance(L, 1);
	mopub->customEventActionDidEnd();
	return 0;
}

static int loader(lua_State *L)
{
	const luaL_Reg functionList[] = {
        {"showBanner", showBanner},
        {"hideBanner", hideBanner},
		{"getAlignment", getAlignment},
		{"setAlignment", setAlignment},
		{"getAutoRefresh", getAutoRefresh},
		{"loadInterstitial", loadInterstitial},
		{"showInterstitial", showInterstitial},
        {"customEventDidLoadAd", customEventDidLoadAd},
        {"customEventDidFailToLoadAd", customEventDidFailToLoadAd},
        {"customEventActionWillBegin", customEventActionWillBegin},
        {"customEventActionDidEnd", customEventActionDidEnd},
		{NULL, NULL}
	};
    
    g_createClass(L, "MoPub", "EventDispatcher", NULL, destruct, functionList);
    
    // create a weak table in LUA_REGISTRYINDEX that can be accessed with the address of keyWeak
	luaL_newweaktable(L, "v");
	luaL_rawsetptr(L, LUA_REGISTRYINDEX, &keyWeak);
    
	lua_getglobal(L, "MoPub");
	lua_pushstring(L, "top");
	lua_setfield(L, -2, "ALIGN_TOP");
	lua_pushstring(L, "bottom");
	lua_setfield(L, -2, "ALIGN_BOTTOM");
	lua_pop(L, 1);
    
    lua_getglobal(L, "Event");
	lua_pushstring(L, AD_WILL_LOAD);
	lua_setfield(L, -2, "AD_WILL_LOAD");
	lua_pushstring(L, AD_LOADED);
	lua_setfield(L, -2, "AD_LOADED");
	lua_pushstring(L, AD_FAILED);
	lua_setfield(L, -2, "AD_FAILED");
	lua_pushstring(L, AD_CLOSED);
	lua_setfield(L, -2, "AD_CLOSED");
	lua_pushstring(L, INTERSTITIAL_LOADED);
	lua_setfield(L, -2, "INTERSTITIAL_LOADED");
	lua_pushstring(L, INTERSTITIAL_FAILED);
	lua_setfield(L, -2, "INTERSTITIAL_FAILED");
	lua_pushstring(L, INTERSTITIAL_CLOSED);
	lua_setfield(L, -2, "INTERSTITIAL_CLOSED");
    lua_pushstring(L, CUSTOM_EVENT);
	lua_setfield(L, -2, "CUSTOM_EVENT");
	lua_pop(L, 1);
    
	MoPub *mopub = new MoPub(L);
	g_pushInstance(L, "MoPub", mopub->object());
    
	luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
	lua_pushvalue(L, -2);
	luaL_rawsetptr(L, -2, mopub);
	lua_pop(L, 1);
    
	lua_pushvalue(L, -1);
	lua_setglobal(L, "mopub");
    
    return 1;
}

static void g_initializePlugin(lua_State *L)
{
    lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
    
	lua_pushcfunction(L, loader);
	lua_setfield(L, -2, "mopub");
    
	lua_pop(L, 2);
}

static void g_deinitializePlugin(lua_State *L)
{
    
}

REGISTER_PLUGIN("MoPub", "2012.12")
