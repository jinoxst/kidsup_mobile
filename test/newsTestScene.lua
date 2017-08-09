---------------------------------------------------------------------------------
-- splashScene
-- Scene notes go here
---------------------------------------------------------------------------------
local ga = require( "scripts.googleAnalytics" )
local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
local language = getLanguage()
local widget = require("widget")
local api = require("scripts.api")
local json = require("json")
require("widgets.widget_newNavBar")

-- local forward references should go here --

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
local navBar

local function onBackButton(event)
    if event.phase == "ended" then
        storyboard.gotoScene( "test.mainScene", "slideRight", 300 ) 
    end

    return true
end

local function callbackListener( event )
    if ( event.isError ) then
        native.setActivityIndicator( false )
        print( "Network error!")
        local alert = native.showAlert( language["appTitle"], language["common"]["wrong_connection"], { language["common"]["alert_ok_button"]}, function() return true end )
    else
        print(event.status)
        if(event.status == 200) then
            print(event.response)
            local data = json.decode(event.response)
                
            if (data) then
                if(data.status == "OK") then
                    local alert = native.showAlert( language["appTitle"], "OK", { language["common"]["alert_ok_button"]}, function() return true end )
                    native.setActivityIndicator( false )
                else
                    native.setActivityIndicator( false )
                    local alert = native.showAlert( language["appTitle"], "NG", { language["common"]["alert_ok_button"]}, function() return true end )
                    return true
                end
            end
        end
    end
end

local function detail3ButtonEvent( event )
    if event.phase == "ended" then
        native.setActivityIndicator( true )
        api.get_news_detail3("72", "1", "4","","1", callbackListener)
    end
    
    return true
end
local function getBadge2ButtonEvent( event )
    if event.phase == "ended" then
        native.setActivityIndicator( true )
        api.get_news2("71", "2", "40", callbackListener)
    end
    
    return true
end
local function setBadge2ButtonEvent( event )
    if event.phase == "ended" then
        native.setActivityIndicator( true )
        api.clear_news2("71", "contact", "40", callbackListener)
    end
    
    return true
end


function scene:createScene( event )
    local group = self.view
    
    local bg = display.newImageRect(group, "images/bg_set/bg_sub.png", __appContentWidth__, __appContentHeight__)
    bg.x = display.contentCenterX
    bg.y = display.contentCenterY

    local btn_left_opt = {
        label = language["top"]["back"],
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__ },
        onEvent = onBackButton,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        width = 100,
        height = 50,
        defaultFile = "images/top_with_texts/btn_top_text_back_normal.png",
        overFile = "images/top_with_texts/btn_top_text_back_touched.png",
    }

    navBar = widget.newNavigationBar({
        title = "Album Test Main",
        width = __appContentWidth__,
        background = "images/top/bg_top.png",
        titleColor = __NAVBAR_TXT_COLOR__,
        font = native.systemFontBold,
        fontSize = __navBarTitleFontSize__,
        leftButton = btn_left_opt
    })    
    group:insert(navBar)
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
    local group = self.view
    
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view
    
    local detail3 = widget.newButton
    {
        width = 130 ,
        height = 40 ,
        defaultFile = "images/button_inframe/btn_inframe_blue_3_normal.png",
        overFile = "images/button_inframe/btn_inframe_blue_3_touched.png",
        labelColor = { default={ 1 }, over={ 1 } },
        emboss = true,
        fontSize = __buttonFontSize__,
        label = "news detail3",
        onRelease = detail3ButtonEvent
    }
    detail3.x = display.contentCenterX
    detail3.y = navBar.height + 30
    group:insert(detail3)
    
    local getBadge2 = widget.newButton
    {
        width = 130 ,
        height = 40 ,
        defaultFile = "images/button_inframe/btn_inframe_blue_3_normal.png",
        overFile = "images/button_inframe/btn_inframe_blue_3_touched.png",
        labelColor = { default={ 1 }, over={ 1 } },
        emboss = true,
        fontSize = __buttonFontSize__,
        label = "getBadge2",
        onRelease = getBadge2ButtonEvent
    }
    getBadge2.x = display.contentCenterX
    getBadge2.y = detail3.y + 50
    group:insert(getBadge2)
    
    local setBadge2 = widget.newButton
    {
        width = 130 ,
        height = 40 ,
        defaultFile = "images/button_inframe/btn_inframe_blue_3_normal.png",
        overFile = "images/button_inframe/btn_inframe_blue_3_touched.png",
        labelColor = { default={ 1 }, over={ 1 } },
        emboss = true,
        fontSize = __buttonFontSize__,
        label = "setBadge2",
        onRelease = setBadge2ButtonEvent
    }
    setBadge2.x = display.contentCenterX
    setBadge2.y = getBadge2.y + 50
    group:insert(setBadge2)
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
    local group = self.view
    
end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene( event )
    local group = self.view
    
--    display:remove(group)
    
end

-- Called prior to the removal of scene's "view" (display view)
function scene:destroyScene( event )
    local group = self.view
    
    group:removeSelf()
end

-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan( event )
    local group = self.view
    local overlay_name = event.sceneName  -- name of the overlay scene
    
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded( event )
    local group = self.view
    local overlay_name = event.sceneName  -- name of the overlay scene
    
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener( "willEnterScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener( "didExitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener( "overlayBegan", scene )

-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener( "overlayEnded", scene )

---------------------------------------------------------------------------------

return scene

