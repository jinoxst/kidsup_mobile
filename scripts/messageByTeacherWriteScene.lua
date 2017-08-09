---------------------------------------------------------------------------------
-- SCENE NAME
-- Scene notes go here
---------------------------------------------------------------------------------
require("scripts.commonSettings")
require("widgets.widget_newNavBar")
require("widgets.widget_sharePanelEx")
require("widgets.widgetext")
require("widgets.activityIndicator")

--local widget = require "widget"
local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
local json = require("json")
local widget = require("widget")
local language = getLanguage()
local user = require("scripts.user_data")
local utils = require("scripts.commonUtils")
local sceneData = require("scripts.sceneData")
local api = require("scripts.api")
local loadsave = require("scripts.loadsave")

local NAVI_BAR_HEIGHT = 50
local NAME_BAR_HEIGHT = 30
local IMAGE_MAX_COUNT = 5
local SELECT_CLASS_BAR = 30

local sharePanel

local photolist --파일명
local photolistGroup    --파일명으로 만든 오브젝트 이미지

local content_textBox

local CONTENT_TEXTBOX_HEIGHT = 100
local activityIndicator

local display_group
local selectedKidsData
local contentField_Move_Y = 100
local button_keyboardOnOff
local imageScrollView

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

local function saveTempFile()
    if(content_textBox.text ~= "") then
        local dataTable = {}
        dataTable.member_id = user.userData.id --작성자 아이디
        dataTable.contents = content_textBox.text --내용

        return loadsave.saveTable(dataTable, __TMP_FILE_MSG_TEACHER_WRITE__, system.DocumentsDirectory)
    else
        return false
    end
end

local function clearScreen()
    native.setKeyboardFocus(nil)
    
    if (display_group.y < 0) then
        transition.to(display_group, {y = 0, time=100, onComplete=nil})
    end
    
    if (button_keyboardOnOff) then
        button_keyboardOnOff.isVisible = false
    end
    
    if (sharePanel and sharePanel.isShowing == true) then
        sharePanel:hide()
        sharePanel.isShowing = false
        
        return true
    end
end

local function freeMemoryAndGo(needRefresh)
    sceneData.freeSceneDataWithUID("photolist")
    sceneData.freeSceneDataWithUID("messageContents")
    sceneData.freeSceneDataWithUID("selectedKidsList")
    
    if(needRefresh and needRefresh == true) then
        storyboard.purgeScene("scripts.messageScene")
    end
    storyboard.gotoScene("scripts.messageScene", "slideRight", 300)
end

local function addPhoto(event)
    if (display_group.y < 0) then
        transition.to(display_group, {y = 0, time=100, onComplete=nil})
    end
    
    if(clearScreen() == true) then
        return true
    end
    
    sceneData.addSceneDataWithUID("photolist", photolist)
    
    if(content_textBox and content_textBox.text ~= "") then
        sceneData.addSceneDataWithUID("messageContents", content_textBox.text)
    end
    
    if(sharePanel) then
        sharePanel:show()
        sharePanel.fromScene = storyboard.getCurrentSceneName()
        sharePanel.imagePath = system.TemporaryDirectory
        sharePanel.imageMaxCount = IMAGE_MAX_COUNT
        sharePanel.isShowing = true
    else
        sharePanel = widget.newSharingPanelEx()
        sharePanel:show()
        sharePanel.fromScene = storyboard.getCurrentSceneName()
        sharePanel.imagePath = system.TemporaryDirectory
        sharePanel.imageMaxCount = IMAGE_MAX_COUNT
        sharePanel.isShowing = true
    end
    
    return true
end

local function getDataCallback(event)
    if(event.isError) then
        print("Post error")    
        activityIndicator:destroy()
        freeMemoryAndGo(false)
    elseif(event.phase == "ended") then
        activityIndicator:destroy()
        local data = json.decode(event.response)
        if (data) then
            if(data.status == "OK") then
                if(data.contact_id) then
                    local contact_id = data.contact_id
                    if(photolist and #photolist > 0) then
                        local photoCount = #photolist
                        local uploadingCount = 0
                        local uploadedCount = 0
                        activityIndicator = ActivityIndicator:new(language["activityIndicator"]["image_upload"])
                        
                        for i = 1, photoCount do
                            if (utils.fileExist(photolist[i], system.TemporaryDirectory) == true) then
                                uploadingCount = uploadingCount + 1
                                
                                local params = {
                                    center_id = user.userData.centerid,
                                    contact_id = contact_id,
                                    filename = photolist[i],
                                    dir = system.TemporaryDirectory
                                }
                                api.post_contact_image(params, 
                                    function(event) 
                                        if(event.isError) then
                                            uploadedCount = uploadedCount + 1

                                            if(uploadingCount == uploadedCount) then
                                                activityIndicator:destroy()
                                                freeMemoryAndGo(true)
                                            end
                                        elseif(event.phase == "ended") then
                                            uploadedCount = uploadedCount + 1

                                            if(uploadingCount == uploadedCount) then
                                                activityIndicator:destroy()
                                                freeMemoryAndGo(true)
                                            end
                                        end
                                    end
                                )
                            end
                        end
                    else
                        freeMemoryAndGo(true)
                    end
                else
                    freeMemoryAndGo(true)
                end
            else
                print("Post error")    
            end
        end
    end
end

local function onLeftButton(event)
    local function isSavedThread()
        if (utils.fileExist(__TMP_FILE_MSG_TEACHER_WRITE__, system.DocumentsDirectory) == true) then
            local tmpData = loadsave.loadTable(__TMP_FILE_MSG_TEACHER_WRITE__, system.DocumentsDirectory)
            if(tmpData.member_id == user.userData.id and tmpData.contents == content_textBox.text) then
                return true
            else
                return false
            end
        else
            return false
        end
    end
    
    if event.phase == "ended" then
        if(clearScreen() == true) then
            return true
        end
        
--        if (__deviceType__ == "iphone") then
--            if (content_textBox.text == language["messageByTeacherWriteScene"]["input_contents"]) then
--                content_textBox.text = ""
--            end
--        end
        
        if(content_textBox.text ~= "" ) then
            if isSavedThread() == false then
                native.showAlert(language["appTitle"], language["messageByTeacherWriteScene"]["delete_question"], 
                    {language["messageByTeacherWriteScene"]["yes"], language["messageByTeacherWriteScene"]["no"]}, 
                    function(event)
                        if "clicked" == event.action then
                            local i = event.index
                            if 1 == i then
                                freeMemoryAndGo(false)    
                            end    
                        end    
                    end
                )
            else
                freeMemoryAndGo(false)    
            end
        else
            freeMemoryAndGo(false)    
        end
    end
    
    return true
end

local function onRightSideButton(event)
    if(event.phase == "ended") then
        if (saveTempFile() == true) then
            utils.showMessage(language["messageByTeacherWriteScene"]["temp_save"])
        end
    end
end

local function onRightButton(event)
    if event.phase == "ended" then
        if(clearScreen() == true) then
            return true
        end
        
        if utils.IS_Demo_mode(storyboard, true) == true then
            return true
        end 
        
        if(content_textBox and content_textBox.text ~= "") then
            if(selectedKidsData ~= nil and selectedKidsData.ids ~= "") then
                local contents = content_textBox.text

                local params = {
                    center_id = user.userData.centerid,
                    class_id = user.userData.classId,
                    member_id = user.userData.id,
                    kids_id = user.getActiveKid_IDByAuthority(),
                    to_kids_id = selectedKidsData.ids, 
                    contents = contents,
                }
                activityIndicator = ActivityIndicator:new(language["activityIndicator"]["send"])
                api.post_contact_contents2(params, getDataCallback)
            else
                utils.showMessage(language["messageByTeacherWriteScene"]["no_kidslist"])
            end
        else
            utils.showMessage(language["messageByTeacherWriteScene"]["input_contents"])
            native.setKeyboardFocus(content_textBox) 
            
            return true
        end
    end
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view
    
    display_group = group
    
    photolist = sceneData.getSceneDataWithUID("photolist")
    if(photolist == nil) then
        photolist = {}
    end    
    
    local bg = display.newImageRect(group, "images/bg_set/bg_sub.png", __backgroundWidth__, __backgroundHeight__)
    bg.x = display.contentWidth / 2
    bg.y = display.contentHeight / 2
    group:insert(bg)
    bg:addEventListener("touch", 
        function(event)
            if(event.phase == "ended") then
                if (display_group.y < 0) then
                    transition.to(display_group, {y = 0, time=100, onComplete=nil})
                end

                native.setKeyboardFocus( nil )

                if(clearScreen() == true) then
                    return true
                end
            end
        end 
    )
    
    local btn_left_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__ },
        label = language["messageByTeacherWriteScene"]["cancel"],
        onEvent = onLeftButton,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        width = 100,
        height = 50,
        defaultFile = "images/top_with_texts/btn_top_text_cancel_normal.png",
        overFile = "images/top_with_texts/btn_top_text_cancel_touched.png", 
    }
    
    local btn_rightSide_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__},
--        label = "임시",
        onEvent = onRightSideButton,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        width = 35,
        height = 50,
        defaultFile = "images/top/btn_top_save_normal.png",
        overFile = "images/top/btn_top_save_touched.png",    
    }
    
    local btn_right_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__ },
--        label = "확인",
        onEvent = onRightButton,
        width = 35,
        height = 50,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        defaultFile = "images/top/btn_top_edit2_normal.png",
        overFile = "images/top/btn_top_edit2_touched.png",    
    }

    local navBar = widget.newNavigationBar({
        title = language["messageByTeacherWriteScene"]["title"],
--        backgroundColor = { 0.96, 0.62, 0.34 },
        width = __appContentWidth__,
        background = "images/top/bg_top.png",
        titleColor = __NAVBAR_TXT_COLOR__,
        font = native.systemFontBold,
        fontSize = __navBarTitleFontSize__,
        leftButton = btn_left_opt,
        rightButton = btn_right_opt,
        rightSideButton = btn_rightSide_opt,
--        includeStatusBar = true
    })
    navBar:addEventListener("touch", 
        function() 
            if(clearScreen() == true) then
                return true
            end
        end 
    )
    group:insert(navBar)
    
    local nameRect = display.newRect(group, display.contentCenterX, __statusBarHeight__ + 65, __appContentWidth__, NAME_BAR_HEIGHT )
    nameRect.strokeWidth = 0
    nameRect:setFillColor( 1, 0, 0 )
    nameRect:setStrokeColor( 0, 0, 0)
    group:insert(nameRect)
    
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
    group:insert(labelTag)
    
    local rect = display.newRect(group, display.contentCenterX, 0, __appContentWidth__, __appContentHeight__)
    rect.anchorY = 0
    rect.y = nameRect.y + nameRect.height - 15
    rect.strokeWidth = 0
    rect:setFillColor( 1, 1, 1 )
    group:insert(rect)
    
    selectedKidsData = sceneData.getSceneDataWithUID("selectedKidsList")
    
    local selectedKidsListRect = display.newRect(group, display.contentCenterX, 0, __appContentWidth__, SELECT_CLASS_BAR)
    selectedKidsListRect.anchorY = 0
    selectedKidsListRect.y = rect.y 
    selectedKidsListRect.strokeWidth = 0
    group:insert(selectedKidsListRect)
    selectedKidsListRect:addEventListener("tap", 
        function()
            if(clearScreen() == true) then
                return true
            end
            
            sceneData.addSceneDataWithUID("messageContents", content_textBox.text) 
            storyboard.isAction = true
            storyboard.purgeScene("scripts.selectKidsScene")
            storyboard.gotoScene("scripts.selectKidsScene", "slideLeft", 300)
        end
    )
    
    local selectedKidsName
    if(selectedKidsData ~= nil and selectedKidsData.names ~= "") then
        local tmpTxt = display.newText(selectedKidsData.names, 0, 0, native.systemFont, 12)
        local namesWidth = tmpTxt.width
        tmpTxt:removeSelf()
        tmpTxt = nil
        
        if(namesWidth > selectedKidsListRect.width - 10) then
            local count = selectedKidsData.count - 1
            local names_txt = selectedKidsData.firstname.." + "..count..language["messageByTeacherWriteScene"]["person"]
            selectedKidsName = display.newText(names_txt, 0, 0, native.systemFont, 12)
        else
            selectedKidsName = display.newText(selectedKidsData.names, 0, 0, native.systemFont, 12)
        end
        
    else
        selectedKidsName = display.newText(language["messageByTeacherWriteScene"]["short_select_kids"], 0, 0, native.systemFont, 12)
    end
    
    selectedKidsName.anchorX = 0
    selectedKidsName.anchorY = 0
    selectedKidsName.x = 10
    selectedKidsName.y = selectedKidsListRect.y + (selectedKidsListRect.height - selectedKidsName.height)/2
    selectedKidsName:setFillColor( 0 )
    group:insert(selectedKidsName)
    
    
    local line = display.newLine( 2, selectedKidsListRect.y + SELECT_CLASS_BAR + 1, display.contentWidth - 2, selectedKidsListRect.y + SELECT_CLASS_BAR + 1 )
    line:setStrokeColor( 0, 0, 0, 0.5)
    line.strokeWidth = 2
    group:insert(line)
    
    imageScrollView = widget.newScrollView
    {
--        top = 0,
--        left = 0,
        width = __appContentWidth__,
        height = 60,
        scrollWidth = __appContentWidth__,
        scrollHeight = 0,
        verticalScrollDisabled = true,
        hideBackground = true,
        listener =  function(event)
                        if(event.phase == "ended") then
                            if(clearScreen() == true) then
                                return true
                            end
                        end
                        
                        return true
                    end
    }    
    imageScrollView.anchorX = 0
    imageScrollView.anchorY = 0
    imageScrollView.x = 0
    imageScrollView.y = nameRect.y + nameRect.height + CONTENT_TEXTBOX_HEIGHT + SELECT_CLASS_BAR  - 5
    group:insert(imageScrollView)
    
    photolistGroup = {} -- 
    local photoImageSize = 60
    local startX = 5
    local function deleteImg(event)
        if(clearScreen() == true) then
            return true
        end
            
        local obj = event.target    
        native.showAlert(language["appTitle"], language["messageByTeacherWriteScene"]["delete_photo"], 
            {language["messageByTeacherWriteScene"]["yes"], language["messageByTeacherWriteScene"]["no"] }, 
            function(event)
                if "clicked" == event.action then
                    local i = event.index
                    if 1 == i then
                        for i = 1, #photolist do
                            if(obj.name == photolist[i]) then
                                local startIndex = i + 1
                                for j = startIndex, #photolistGroup do
                                    local child = photolistGroup[j]
                                    if(child) then
                                        local originX = child.x
                                        transition.to( child, { time=200, x=(originX - photoImageSize - 5), nil})

                                        local originX = child.deleteIcon.x
                                        transition.to( child.deleteIcon, { time=200, x=(originX - photoImageSize - 5), nil})
                                    end
                                end

                                display.remove(photolistGroup[i].deleteIcon)
                                table.remove(photolist, i)
                                table.remove(photolistGroup, i)
                                display.remove(obj)

                                break
                            end
                        end
                    end
                end    
            end
        )
        
        return true
    end
    
    local addPhotoButton = widget.newButton
    {
        width = photoImageSize,
        height = photoImageSize,
        defaultFile = "images/assets1/icon_photo.png",
        overFile = "images/assets1/icon_photo.png",
        fontSize = __buttonFontSize__,
        onRelease = addPhoto,
    }
    addPhotoButton.anchorX = 0
    addPhotoButton.anchorY = 0
    addPhotoButton.x = startX
    addPhotoButton.y = (imageScrollView.contentHeight - addPhotoButton.height) / 2
    imageScrollView:insert(addPhotoButton)
    
    local notExistFileindex = {}
    for i = 1, #photolist do
        if(utils.fileExist(photolist[i], system.TemporaryDirectory) == true) then
            photolistGroup[i] = display.newImageRect(photolist[i], system.TemporaryDirectory, 0, 0 )
            photolistGroup[i].width = photoImageSize
            photolistGroup[i].height = photoImageSize
            photolistGroup[i].anchorX = 0
            photolistGroup[i].anchorY = 0

            if(i==1) then
                photolistGroup[i].x = addPhotoButton.x + addPhotoButton.width + 5
            else
                local tmp = photolistGroup[i-1]
                photolistGroup[i].x = tmp.x + tmp.width + 5
            end

            photolistGroup[i].y = 0
            photolistGroup[i].name = photolist[i]
            imageScrollView:insert(photolistGroup[i])
            
            photolistGroup[i].deleteIcon = display.newImageRect("images/assets1/icon_delete_photo.png", 20, 20)
            photolistGroup[i].deleteIcon.anchorX = 0
            photolistGroup[i].deleteIcon.anchorY = 0
            photolistGroup[i].deleteIcon.x = photolistGroup[i].x + photolistGroup[i].width - photolistGroup[i].deleteIcon.width
            photolistGroup[i].deleteIcon.y = photolistGroup[i].height - photolistGroup[i].deleteIcon.height
            imageScrollView:insert(photolistGroup[i].deleteIcon)
            
            photolistGroup[i]:addEventListener("tap", deleteImg)
        else
            table.insert(notExistFileindex, i) --존재하지 않는 파일 얻기
        end
    end
    
    for i = #photolist, 1 , -1 do --존재하지 않는 파일 photolist에서 삭제
        for j = 1, #notExistFileindex do
            if(i == notExistFileindex[j]) then
                table.remove(photolist, i)
                
                break
            end
        end
    end
    
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
    local group = self.view
    
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view
    
    local function contents_inputListener( event )
        if event.phase == "began" then
            transition.to(display_group, {y = - contentField_Move_Y, time=100, onComplete=nil})
            if(button_keyboardOnOff) then
                button_keyboardOnOff.isVisible = true
            end    
            
            if (sharePanel and sharePanel.isShowing == true) then
                sharePanel:hide()
                sharePanel.isShowing = false
            end    
            
--            if (__deviceType__ == "iphone") then
--                if (content_textBox.text == language["messageByTeacherWriteScene"]["input_contents"]) then
--                    content_textBox.text = ""
--                end
--            end
        elseif event.phase == "ended" then
--            if (__deviceType__ == "iphone") then
--                if (content_textBox.text == "") then
--                    content_textBox.text = language["messageByTeacherWriteScene"]["input_contents"]
--                end
--            end
        elseif event.phase == "editing" then
            print( event.text )
            
        end
    end
    
    content_textBox = native.newTextBox(display.contentCenterX,
            CONTENT_TEXTBOX_HEIGHT/2 + __statusBarHeight__+ NAVI_BAR_HEIGHT + NAME_BAR_HEIGHT + SELECT_CLASS_BAR + 3,
            __appContentWidth__ - 2 , 
            CONTENT_TEXTBOX_HEIGHT)
    content_textBox.text = ""
    content_textBox.placeholder = language["messageByTeacherWriteScene"]["input_contents"]
    content_textBox.isEditable = true
    content_textBox.strokeWidth = 0
    content_textBox.hasBackground = false
    content_textBox:addEventListener( "userInput", contents_inputListener )
    content_textBox.font = native.newFont(native.systemFont, __INPUT_TEXT_FONT_SIZE__)
    content_textBox.ori_y = content_textBox.y
    local content_text = sceneData.getSceneDataWithUID("messageContents")
    if(content_text) then
        content_textBox.text = content_text
    end
    
--    if (__deviceType__ == "iphone") then
--        if(content_textBox.text == "") then
--            content_textBox.text = language["messageByTeacherWriteScene"]["input_contents"]
--        end
--    end
    group:insert(content_textBox)
--    native.setKeyboardFocus(content_textBox)
    
    if (utils.fileExist(__TMP_FILE_MSG_TEACHER_WRITE__, system.DocumentsDirectory) == true) then
        local tmpData = loadsave.loadTable(__TMP_FILE_MSG_TEACHER_WRITE__, system.DocumentsDirectory)
        if(tmpData.member_id == user.userData.id) then
            native.showAlert(language["appTitle"], language["messageByTeacherWriteScene"]["read_question"], 
                { language["messageByTeacherWriteScene"]["yes"], language["messageByTeacherWriteScene"]["no"] }, 
                function(event)
                    if "clicked" == event.action then
                        local i = event.index
                        if 1 == i then
                            content_textBox.text = tmpData.contents
                            
                            utils.deleteFile(__TMP_FILE_MSG_TEACHER_WRITE__, system.DocumentsDirectory)
                        end    
                    end    
                end
            )
        end
    end
    
    button_keyboardOnOff = widget.newButton
    {
        left = 0,
        top = 0,
        width = 60,
        height = 20,
        font = native.systemFont,
        fontSize = 10,
        defaultFile = "images/assets1/btn_key_off.png",
        overFile = "images/assets1/btn_key_off.png",
        onRelease = function(event)
                        native.setKeyboardFocus(nil)
                        
                        if (display_group.y < 0) then
                            transition.to(display_group, {y = 0, time=100, onComplete=nil})
                        end
                        
                        button_keyboardOnOff.isVisible = false
                    end,
    }
    button_keyboardOnOff.anchorX = 0
    button_keyboardOnOff.anchorY = 0
    button_keyboardOnOff.x = __appContentWidth__ - button_keyboardOnOff.width - 10
    button_keyboardOnOff.y = imageScrollView.y + imageScrollView.height + 2
    button_keyboardOnOff.isVisible = false
    group:insert(button_keyboardOnOff)
    
    storyboard.isAction = false
    storyboard.returnTo = "scripts.messageScene"
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
    local group = self.view
    
    native.setKeyboardFocus(nil)
    
    if(content_textBox) then
        content_textBox:removeSelf()
        content_textBox = nil
    end
    
    for i = #photolistGroup, 1 do
        local child = photolistGroup[i]
        if(child) then
            display.remove(child)
        end
    end
    
    if (sharePanel) then
        sharePanel.isShowing = false
        sharePanel:hide()
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







