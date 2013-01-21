require "mopub"

print("MoPub test")

-- LIST OF EVENTS --

mopub:addEventListener(Event.AD_WILL_LOAD, function()
	print("AD_WILL_LOAD")
end)

mopub:addEventListener(Event.AD_LOADED, function()
	print("AD_LOADED")
end)

mopub:addEventListener(Event.AD_FAILED, function()
	print("AD_FAILED")
end)

mopub:addEventListener(Event.AD_CLOSED, function()
	print("AD_CLOSED")
	mopub:showInterstitial()
end)

mopub:addEventListener(Event.INTERSTITIAL_LOADED, function()
	print("INTERSTITIAL_LOADED")
end)

mopub:addEventListener(Event.INTERSTITIAL_FAILED, function()
	print("INTERSTITIAL_FAILED")
end)

mopub:addEventListener(Event.INTERSTITIAL_CLOSED, function()
	print("INTERSTITIAL_CLOSED")
end)

mopub:addEventListener(Event.CUSTOM_EVENT, function(event)
	print("CUSTOM_EVENT")
	print(event.name)
end)

-- LIST OF API --

-- show banner
mopub:showBanner("agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA")

-- load interstitial content first
mopub:loadInterstitial("agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA")

-- show interstitial
--mopub:showInterstitial()

-- return current banner allignment, value must be MoPub.ALIGN_TOP or MoPub.ALIGN_BOTTOM
--mopub:getAlignment()

-- set current banner allignment
--mopub:setAlignment()

-- return value of refresh
--mopub:getAutoRefresh()

-- custom event related functions
--mopub:customEventDidLoadAd()
--mopub:customEventDidFailToLoadAd()
--mopub:customEventActionWillBegin()
--mopub:customEventActionDidEnd()