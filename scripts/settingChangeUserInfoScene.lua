---------------------------------------------------------------------------------
-- SCENE NAME
-- Scene notes go here
---------------------------------------------------------------------------------
require("scripts.commonSettings")
require("widgets.widget_newNavBar")
require("widgets.activityIndicator")
require("widgets.widgetext")

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
local widget = require("widget")
local language = getLanguage()
local user = require("scripts.user_data")
local api = require("scripts.api")
local utils = require("scripts.commonUtils")
local json = require("json")
local activityIndicator

local NAVI_BAR_HEIGHT = 50
local NAME_BAR_HEIGHT = 30
local TEXTBOX_HEIGHT = 40
local navBar
local nameRect
local username_textBox
local phone_textBox

--widget.setTheme( "widget_theme_ios7" )

local function getDataCallback(event)   
    if(activityIndicator) then
        activityIndicator:destroy()
    end
    
    if ( event.isError ) then
        print( "Network error!")
        utils.showMessage(language["common"]["wrong_connection"])
    else
        print(event.status)
        if(event.status == 200) then
            print ( "RESPONSE: " .. event.response )
            local data = json.decode(event.response)
        
            if (data) then
                if(data.status == "OK") then
                    user.userData.name = username_textBox:getText()
                    user.userData.phonenum = phone_textBox:getText()
                    
                    utils.showMessage(language["settingChangeUserInfoScene"]["changed"])
                    
                    storyboard.purgeScene("scripts.settingScene")
                    storyboard.gotoScene("scripts.settingScene", "slideRight", 300)
                end
            end
        end
    end
    return true
end

local function onLeftButton(event)
    if event.phase == "ended" then
        storyboard.purgeScene("scripts.settingScene")
        storyboard.gotoScene("scripts.settingScene", "slideRight", 300)
    end
    
    return true
end

local function onRightButton(event)
    if event.phase == "ended" then
        if utils.IS_Demo_mode(storyboard, true) == true then
            return true
        end
        
        local user_name = username_textBox:getText()
        local user_phone = phone_textBox:getText()
        
        if (user_name ~= "") then
            if (user_phone ~= "") then
                native.setKeyboardFocus(nil)

                native.showAlert(language["appTitle"], language["settingChangeUserInfoScene"]["save_question"], 
                    {language["settingChangeUserInfoScene"]["yes"], language["settingChangeUserInfoScene"]["no"] }, 
                    function(event)
                        if "clicked" == event.action then
                            local i = event.index
                            if 1 == i then
                                activityIndicator = ActivityIndicator:new(language["activityIndicator"]["save"])
                                api.update_member3_info(user.userData.id, user_name, user_phone, getDataCallback)
                            end
                        end
                    end
                )    
            else
                utils.showMessage(language["settingChangeUserInfoScene"]["input_phone"])
                phone_textBox:setEditMode(true)
            end
        else
            utils.showMessage(language["settingChangeUserInfoScene"]["input_name"])
            username_textBox:setEditMode(true)
        end
    end    
    
    return true
end
-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view
    
    local bg = display.newRect(group, 0, 0, __appContentWidth__, __appContentHeight__)
    bg.strokeWidth = 0
    bg:setFillColor( 1, 1, 1 )
--    bg:setStrokeColor( 0, 0, 0)
    bg.x = display.contentWidth / 2
    bg.y = display.contentHeight / 2
    group:insert(bg)
    
    local btn_left_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__},
        label = language["settingChangeUserInfoScene"]["cancel"],
        onEvent = onLeftButton,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        width = 100,
        height = 50,
        defaultFile = "images/top_with_texts/btn_top_text_cancel_normal.png",
        overFile = "images/top_with_texts/btn_top_text_cancel_touched.png",    
    }
    
    local btn_right_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__},
        label = language["settingChangeUserInfoScene"]["ok"],
        onEvent = onRightButton,
        width = 100,
        height = 50,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        defaultFile = "images/top_with_texts/btn_top_text_ok_normal.png",
        overFile = "images/top_with_texts/btn_top_text_ok_touched.png",
    }

    nameRect = display.newRect(group, display.contentCenterX, __statusBarHeight__ + 65, __appContentWidth__, NAME_BAR_HEIGHT )
    nameRect.strokeWidth = 0
    nameRect:setFillColor( 1, 0, 0 )
    nameRect:setStrokeColor( 0, 0, 0)
    
    local tag_Opt = {
        parent = group,
        text = user.getNameTagByAuthority(),
        x = display.contentCenterX,
        width = __appContentWidth__,
        y = __statusBarHeight__ + 68,
        font = native.systemFontBold,
        fontSize = __buttonFontSize__,
        align = "center"
    }
    
    local labelTag = display.newText(tag_Opt)
    labelTag:setFillColor( 1 )
    
    navBar = widget.newNavigationBar({
            title = language["settingChangeUserInfoScene"]["title"],
    --        backgroundColor = { 0.96, 0.62, 0.34 },
            width = __appContentWidth__,
            background = "images/top/bg_top.png",
            titleColor = __NAVBAR_TXT_COLOR__,
            font = native.systemFontBold,
            fontSize = __navBarTitleFontSize__,
            leftButton = btn_left_opt,
            rightButton = btn_right_opt
        })
    navBar:addEventListener("touch", function() return true end )
    group:insert(navBar)
--    native.setActivityIndicator( true )
    
    local loc_x = 25
    local username_text = display.newText(language["settingChangeUserInfoScene"]["user_name"], 0, 0, native.systemFontBold, __textLabelFont14Size__)
    username_text.anchorX = 0
    username_text.anchorY = 0
    username_text.x = loc_x--(display.contentWidth - currentPassword_text.width) * 0.5
    username_text.y = nameRect.y + nameRect.height*0.5 + 10
    username_text:setFillColor(0,0,0)
    group:insert(username_text)
    
    username_textBox = widget.newEditField
    {
        width = display.contentWidth - 50,
        editHintColor = {1,1,1,1},
        hint = "",--user.userData.name,
        editFont = native.systemFontBold,
        editFontSize = __textFieldFontSize__,
        editFontColor = {1,1,1,1},
--        slideGroup = group,
        maxChars = 16,
        frame = {
            cornerRadius = 1,
            strokeWidth = 1,
            strokeColor = __EDITFIELD_FILL_COLOR__,
            fillColor = __EDITFIELD_FILL_COLOR__
          },
        required = true,
        errorFrame = {
           cornerRadius = 1
        },
        buttons = {
            {
                kind = "clear",
                defaultFile = "images/widgets/clear.png"
            }
        }
    }
    username_textBox.anchorY = 0
    username_textBox.x = display.contentCenterX --loc_x
    username_textBox.y = username_text.y + username_text.height + 2
    group:insert(username_textBox)
    username_textBox:setText(user.userData.name)
    
    
    local phone_text = display.newText(language["settingChangeUserInfoScene"]["user_phone"], 0, 0, native.systemFontBold, __textLabelFont14Size__)
    phone_text.anchorX = 0
    phone_text.anchorY = 0
    phone_text.x = loc_x
    phone_text.y = username_textBox.y + username_textBox.height + 10
    phone_text:setFillColor(0,0,0)
    group:insert(phone_text)
    
    phone_textBox = widget.newEditField
    {
        width = display.contentWidth - 50,
        editHintColor = {1,1,1,1},
        hint = "",--user.userData.phonenum,
        editFont = native.systemFontBold,
        editFontSize = __textFieldFontSize__,
        editFontColor = {1,1,1,1},
--        slideGroup = group,
        maxChars = 16,
        frame = {
            cornerRadius = 1,
            strokeWidth = 1,
            strokeColor = __EDITFIELD_FILL_COLOR__,
            fillColor = __EDITFIELD_FILL_COLOR__
          },
        required = true,
        errorFrame = {
           cornerRadius = 1
        },
        inputType = "phone",
        buttons = {
            {
                kind = "clear",
                defaultFile = "images/widgets/clear.png"
            }
        }
    }
    phone_textBox.anchorY = 0
    phone_textBox.x = display.contentCenterX --loc_x
    phone_textBox.y = phone_text.y + phone_text.height + 2
    group:insert(phone_textBox)
    phone_textBox:setText(user.userData.phonenum)
    
--    confirmPassword_textBox = widget.newEditField
--    {
--        width = display.contentWidth - 50,
--        editHintColor = {1,1,1,1},
--        hint = language["settingChangePasswordScene"]["confirm_password"],
--        editFont = native.systemFontBold,
--        editFontSize = __textFieldFontSize__,
--        editFontColor = {1,1,1,1},
----        slideGroup = group,
--        maxChars = 16,
--        frame = {
--            cornerRadius = 1,
--            strokeWidth = 1,
--            strokeColor = __EDITFIELD_FILL_COLOR__,
--            fillColor = __EDITFIELD_FILL_COLOR__
--          },
--        required = true,
--        errorFrame = {
--           cornerRadius = 1
--        },
--        buttons = {
--            {
--                kind = "clear",
--                defaultFile = "images/widgets/clear.png"
--            }
--        }
--    }
--    confirmPassword_textBox.isSecure = true
----    confirmPassword_textBox.anchorX = 0
--    confirmPassword_textBox.anchorY = 0
--    confirmPassword_textBox.x = display.contentCenterX --loc_x
--    confirmPassword_textBox.y = newPassword_textBox.y + newPassword_textBox.height + 2
--    group:insert(confirmPassword_textBox)
--    
--    print(confirmPassword_textBox.width)
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
    local group = self.view
    
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view
    
    storyboard.isAction = false
    storyboard.returnTo = "scripts.settingScene"
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
    local group = self.view
    
    native.setKeyboardFocus(nil)
    
    if (currentPassword_textBox) then
        currentPassword_textBox:removeSelf()
        currentPassword_textBox = nil
    end
    
    if(newPassword_textBox) then
        newPassword_textBox:removeSelf()
        newPassword_textBox = nil
    end
    
    if(confirmPassword_textBox) then
        confirmPassword_textBox:removeSelf()
        confirmPassword_textBox = nil
    end
end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene( event )
    local group = self.view
    
end

-- Called prior to the removal of scene's "view" (display view)
function scene:destroyScene( event )
    local group = self.view
    
end

-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan( event )
    local group = self.view
    local overlay_name = event.sceneName  -- name of the overlay scene
    print( "Showing overlay: " .. event.sceneName )
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded( event )
    local group = self.view
    local overlay_name = event.sceneName  -- name of the overlay scene
    print( "Overlay removed: " .. event.sceneName )
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



