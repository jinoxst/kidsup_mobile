---------------------------------------------------------------------------------
-- SCENE NAME
-- Scene notes go here
---------------------------------------------------------------------------------
require("scripts.commonSettings")
require("widgets.widget_newNavBar")
require("widgets.widgetext")

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
local json = require("json")
local widget = require("widget")
local language = getLanguage()
local utils = require("scripts.commonUtils")
local tablespinner = require ("scripts.tablespinner")
local api = require("scripts.api")
local user = require("scripts.user_data")
local authority = require("scripts.user_authority")
local sceneData = require("scripts.sceneData")
local userSetting = require("scripts.userSetting")

local REFRESH_ROW_HEIGHT = 50
local NAVI_BAR_HEIGHT = 50
local NAME_BAR_HEIGHT = 30
local COMMENT_BOX_HEIGHT = 40
local TOP_PADDING = 10
local LEFT_PADDING = 5
local COMMENT_TOP_PADDING = 10

local springStart = 0
local needToReload = false
local needToPastload = false
local pullDown = nil
local reloadspinner
local reloadInProgress = false
local msgTable
local pageno = 1 --페이징 번호
local pagesize = 10 --리스트 갯수
local springStart
local cropedImageSize = 280
local contentImagePadding = 10

local oData
local message_id
local photolist

local imageGroup 
local activityIndicator
local isOverlay = false
local firstCommentID = nil

local tablespinnerImageSheet = graphics.newImageSheet( "images/etc/tablespinner.png", tablespinner:getSheet() )	

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
local function getHeightofString(str, _width, _font, _fontSize)
    local content_txt_options = 
    {
        text = "",     
        width = _width,
        font = _font,   
        fontSize = _fontSize,
        align = "left",  --new alignment parameter
    }
    local height = utils.getParagraphContentsHeight(str, content_txt_options)
    return height
end

local function getHeightofImages(list)
    local function getHeight(oWidth, oHeight) 
        local scaleFactor = cropedImageSize/oWidth 
	local newHeight = oHeight * scaleFactor
        local newWidth = oWidth * scaleFactor
        
        return newWidth, newHeight
    end
    
    local sum_height = 0
    local newWidth
    local newHeight
    
    if(list.img1 and list.img1.url and list.img1.url ~= "") then
        newWidth, newHeight = getHeight(list.img1.w, list.img1.h)
        list.img1.new_w = newWidth
        list.img1.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img2 and list.img2.url and list.img2.url ~= "") then
        newWidth, newHeight = getHeight(list.img2.w, list.img2.h)
        list.img2.new_w = newWidth
        list.img2.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img3 and list.img3.url and list.img3.url ~= "") then
        newWidth, newHeight = getHeight(list.img3.w, list.img3.h)
        list.img3.new_w = newWidth
        list.img3.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img4 and list.img4.url and list.img4.url ~= "") then
        newWidth, newHeight = getHeight(list.img4.w, list.img4.h)
        list.img4.new_w = newWidth
        list.img4.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img5 and list.img5.url and list.img5.url ~= "") then
        newWidth, newHeight = getHeight(list.img5.w, list.img5.h)
        list.img5.new_w = newWidth
        list.img5.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img6 and list.img6.url and list.img6.url ~= "") then
        newWidth, newHeight = getHeight(list.img6.w, list.img6.h)
        list.img6.new_w = newWidth
        list.img6.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img7 and list.img7.url and list.img7.url ~= "") then
        newWidth, newHeight = getHeight(list.img7.w, list.img7.h)
        list.img7.new_w = newWidth
        list.img7.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img8 and list.img8.url and list.img8.url ~= "") then
        newWidth, newHeight = getHeight(list.img8.w, list.img8.h)
        list.img8.new_w = newWidth
        list.img8.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img9 and list.img9.url and list.img9.url ~= "") then
        newWidth, newHeight = getHeight(list.img9.w, list.img9.h)
        list.img9.new_w = newWidth
        list.img9.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    if(list.img10 and list.img10.url and list.img10.url ~= "") then
        newWidth, newHeight = getHeight(list.img10.w, list.img10.h)
        list.img10.new_w = newWidth
        list.img10.new_h = newHeight
        sum_height = sum_height + newHeight + contentImagePadding
    end
    
    return sum_height
end

local function reloadTable()
    local function reloadcomplete()   
        if (reloadspinner ~= nil) and (reloadspinner.x ~= nil) then 
	    reloadspinner:stop()
            reloadspinner.alpha = 0
        end	 	   
	transition.to( pullDown, { time=50, rotation=0, onComplete= function()	
                if (pullDown ~= nil) and (pullDown.x ~= nil) then
                    pullDown.alpha = 1; 
	   	end
                reloadInProgress = false; 
	end } )        	 
    end

    local reloadCompleteTimer = timer.performWithDelay( 200, reloadcomplete, 1 )      	 
end

local function alignImage(row, filename, dir, x, y, width, height, contentsImage, id)
    local img
    
    if(dir) then
        img = display.newImage(row, filename, dir )
    else
        img = display.newImage(row, filename)
    end
    
    if(img) then
        if(contentsImage == true) then
            local function onContensImageTap( event )
                if(isOverlay == true) then
                    isOverlay = false
                    return true
                end

                local options =
                {
                    effect = "fade",
                    time = 300,
                    isModal = true,
                    params =
                    {
                        slideImageList = row.rowSlideImages,
                        startFileName = event.target.startFileName,
                        thread_id = message_id,
                        previous_scene = storyboard.getCurrentSceneName()
                    }
                }
                local selectedImg = display.getCurrentStage()
                if(selectedImg) then
                    selectedImg:setFocus( selectedImg)
                    selectedImg.isFocus = true
                    storyboard.showOverlay("scripts.slideImageViewer", options )

                    selectedImg:setFocus( nil)
                    selectedImg.isFocus = false
                end
            end
            
            img.startFileName = filename
            
            table.insert(row.rowSlideImages, filename) 
            img:addEventListener( "tap", onContensImageTap)
        end    
        
        img.alpha = 0
        img.anchorX = 0
        img.anchorY = 0
--        local scalePoint =  cropedImageSize / width
--        img.width = width * scalePoint
--        img.height = height * scalePoint
        img.width = width
        img.height = height
        img.x = x
        img.y = y
        
        transition.to(img, { alpha = 1.0 } )
        imageGroup:insert(img)
        row:insert(img)
    end
    
    return true
end

local function translatorView(event)
    local srcContents = event.target.srcContents
    local srcTitle = event.target.srcTitle
    
    if(srcContents and srcContents ~= "") then
        local options = {
            effect = "fromRight",
            time = 300,
            isModal = true,
            params = {
                srcTitle = srcTitle,
                srcContents = srcContents
            }
        }
        isOverlay = true
        storyboard.showOverlay("scripts.translatorViewScene", options) 
    end
end

local function displayView()
    if(msgTable) and (oData) then
        local imagesHeight = getHeightofImages(oData)
        local contentRowHeight = getHeightofString(oData.contents, msgTable.width - 22, native.systemFont, __VIEW_SCENE_TEXT_SIZE__)
        
        msgTable:insertRow{  -- this is the row containing the pulldown arrow/spinner
            rowHeight = REFRESH_ROW_HEIGHT,
            rowColor = {  default = { 1, 1, 1,0 }, over = { 1, 1, 1, 0}},
        }
        msgTable:insertRow{
            rowHeight = contentRowHeight + imagesHeight + 150,
            rowColor = {  default = { 1, 1, 1,0 }, over = { 1, 1, 1, 0}},
--            lineColor = { 0.5, 0.5, 0.5 },
            params = { rowData = oData }
        }
    end
    
    return true
end

local function onRowRender( event )
    local row = event.row
    local index = row.index 
    local rowData = row.params.rowData
    
    if index == 1 then 
        if (pullDown == nil) or (pullDown.x == nil) then
            pullDown = display.newImage( row, "images/etc/downloadarrow.png")
            pullDown.anchorX = 0.5
            pullDown.anchorY = 0.5
            pullDown.x = __appContentWidth__ * 0.5
            pullDown.y = REFRESH_ROW_HEIGHT * 0.5
	else
            pullDown.alpha = 1
	end

	if (reloadspinner == nil)  or (reloadspinner.x == nil) then
            reloadspinner = widget.newSpinner
            {
                width = 128,
		height = 128,
                sheet = tablespinnerImageSheet,
		startFrame = 1,
		count = 8,
		time = 800
            }
	
            reloadspinner.alpha = 0	
            reloadspinner.anchorX = 0.5
            reloadspinner.anchorY = 0.5
            reloadspinner.x = __appContentWidth__*0.5
            reloadspinner.y = REFRESH_ROW_HEIGHT * 0.5
	end
		
	row:insert(reloadspinner)
        
        return
    end
    
    if(rowData) and (index == 2)  then
        row.rowSlideImages = {}
        photolist = row.rowSlideImages
        
        row.viewPanel = display.newRoundedRect(row.width/2, row.height/2, row.width - 12, row.height - 10, 6)
        row.viewPanel.anchorX= 0
        row.viewPanel.anchorY = 0
        row.viewPanel.x = (row.width - row.viewPanel.width) /2
        row.viewPanel.y = 5
        row.viewPanel.height = row.height - TOP_PADDING
        row:insert(row.viewPanel)
            
        local writerImgFileName
        if(rowData.writer.img) then
            writerImgFileName = rowData.writer.img:match("([^/]+)$")         
        end
            
        local imageWidth = 30
        local imageHeight = 30
        if(writerImgFileName) then
            if(utils.fileExist(writerImgFileName, system.TemporaryDirectory) == true) then
                alignImage(row, writerImgFileName, system.TemporaryDirectory, 
                    row.viewPanel.x + LEFT_PADDING, TOP_PADDING, imageWidth, imageHeight, false)
            else
                local requestId = 
                    network.download(
                        rowData.writer.img,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                alignImage(row, "images/assets1/pic_photo_30x30.png", nil, 
                                row.viewPanel.x + LEFT_PADDING, TOP_PADDING, imageWidth, imageHeight, false) 
                            elseif ( event.phase == "ended" ) then
                               alignImage(row, writerImgFileName, system.TemporaryDirectory, 
                                row.viewPanel.x + LEFT_PADDING, TOP_PADDING, imageWidth, imageHeight, false)  
                            end
                        end ,
                        writerImgFileName,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
        else
        --      default image  
            writerImgFileName = "images/assets1/pic_photo_80x80.png"
            alignImage(row, writerImgFileName, nil, 
                row.viewPanel.x + LEFT_PADDING, TOP_PADDING, imageWidth, imageHeight, false)
        end
        
        local writer_txt_options = 
        {
            text = rowData.writer.name,
--            width = row.viewPanel.width - LEFT_PADDING - imageWidth,
            font = native.systemFontBold,   
            fontSize = 12,
            align = "left",  --new alignment parameter
        }
        row.txt_writer = display.newText(writer_txt_options)
        row.txt_writer:setFillColor(unpack(__Read_NoticeList_FontColor__))
        row.txt_writer.anchorX = 0
        row.txt_writer.anchorY = 0
        row.txt_writer.x = imageWidth + LEFT_PADDING + 10
        row.txt_writer.y = TOP_PADDING
        row:insert(row.txt_writer)
        
        row.classname = display.newText("(" .. rowData.class.name .. ")", 12, 0, native.systemFont, 12)
        row.classname.anchorX = 0
        row.classname.anchorY = 0
        row.classname:setFillColor(unpack(__Read_NoticeList_FontColor__))
        row.classname.x = row.txt_writer.x + row.txt_writer.width + 5
        row.classname.y = row.txt_writer.y
        row:insert(row.classname)
        
        local createTime_txt_options = 
        {
            text = rowData.createtime,
            width = row.viewPanel.width - LEFT_PADDING - imageWidth,
            font = native.systemFontBold,   
            fontSize = 12,
            align = "left",  --new alignment parameter
        }
        row.txt_createTime = display.newText(createTime_txt_options)
        row.txt_createTime:setFillColor( unpack(__Read_NoticeList_FontColor__) )
        row.txt_createTime.anchorX = 0
        row.txt_createTime.anchorY = 0
        row.txt_createTime.x = row.txt_writer.x
--        row.txt_createTime.y = TOP_PADDING + row.txt_title.height + row.underline.height
        row.txt_createTime.y = TOP_PADDING + row.txt_writer.height
        row:insert(row.txt_createTime)
            
        local content_txt_options = 
        {
            text = rowData.contents,     
            width = row.viewPanel.width - 10,
            font = native.systemFont,   
            fontSize = __VIEW_SCENE_TEXT_SIZE__,
            align = "left",  --new alignment parameter
        }
        
        row.paragraphs = {}
        local yOffset = utils.setParagraphContents(row, rowData.contents, content_txt_options, row.txt_createTime.y + row.txt_createTime.height, row.viewPanel.x + 5)
        
        local urlTable = utils.getURLfromContents(rowData.contents)
        for i = 1, #urlTable do
            content_txt_options.text = urlTable[i]
            
            local url_text = display.newText(content_txt_options)
            url_text.anchorX = 0
            url_text.anchorY = 0
            url_text.x = row.viewPanel.x + LEFT_PADDING
            url_text.y = yOffset + 5
            row:insert(url_text)
            url_text:setFillColor( unpack( __URL_LINK_COLOR__ ))
            yOffset = yOffset + url_text.height + 5

            url_text:addEventListener("tap", 
                function()
                    system.openURL( urlTable[i] )
                end
            )
        end
        
        if(userSetting.settings.toTranslatorLanguageCode ~= "")then
            row.transButton = display.newText(language["messageViewScene"]["translation"], 0, 0, native.systemFont, 12)
            row.transButton.anchorX = 0
            row.transButton.anchorY = 0
            row.transButton:setFillColor(0, 0, 1)
            row.transButton.x = row.viewPanel.x + LEFT_PADDING
            row.transButton.y = yOffset + 10
            row.transButton.srcTitle = rowData.title
            row.transButton.srcContents = rowData.contents
            row:insert(row.transButton)

            row.transButton:addEventListener("tap", translatorView)
        end
        
        local sumY
        if row.transButton then
            sumY = row.transButton.y + row.transButton.height + contentImagePadding
        else
            sumY = yOffset + contentImagePadding + 10
        end
        
        local imgX = (row.width - cropedImageSize) /2
        if(rowData.img1 and rowData.img1.url and rowData.img1.url ~= "") then
            local ImgFileName1 = rowData.img1.url:match("([^/]+)$")         
            local imgY_1 = sumY
            
            if(utils.fileExist(ImgFileName1, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName1
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_1
                    , rowData.img1.new_w
                    , rowData.img1.new_h,
                    true, 1)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_1, rowData.img1.new_w, rowData.img1.new_h)
                local requestId =
                    network.download(
                        rowData.img1.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_1, rowData.img1.new_w, rowData.img1.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName1, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_1
                                    , rowData.img1.new_w
                                    , rowData.img1.new_h
                                    , true, 1
                                )
                            end
                        end ,
                        ImgFileName1,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            
            sumY = sumY + rowData.img1.new_h + contentImagePadding
        end
        
        local ImgFileName2
        if(rowData.img2 and rowData.img2.url and rowData.img2.url ~= "") then
            ImgFileName2 = rowData.img2.url:match("([^/]+)$")         
            local imgY_2 = sumY 
--            sumY = sumY + rowData.img1.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName2, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName2
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_2
                    , rowData.img2.new_w
                    , rowData.img2.new_h
                    , true, 2)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_2, rowData.img2.new_w, rowData.img2.new_h)
                local requestId =
                    network.download(
                        rowData.img2.url,
                        "GET",
                        function(event)
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_2, rowData.img2.new_w, rowData.img2.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName2, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_2
                                    , rowData.img2.new_w
                                    , rowData.img2.new_h
                                    , true, 2
                                )
                            end
                        end ,
                        ImgFileName2,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img2.new_h + contentImagePadding
        end
        
        local ImgFileName3
        if(rowData.img3 and rowData.img3.url and rowData.img3.url ~= "") then
            ImgFileName3 = rowData.img3.url:match("([^/]+)$")         
            local imgY_3 = sumY
--            sumY = sumY + rowData.img2.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName3, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName3
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_3
                    , rowData.img3.new_w
                    , rowData.img3.new_h
                    , true, 3)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_3, rowData.img3.new_w, rowData.img3.new_h)
                local requestId =
                    network.download(
                        rowData.img3.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_3, rowData.img3.new_w, rowData.img3.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName3, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_3
                                    , rowData.img3.new_w
                                    , rowData.img3.new_h
                                    , true, 3
                                )
                            end
                        end ,
                        ImgFileName3,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img3.new_h + contentImagePadding
        end
        
        local ImgFileName4
        if(rowData.img4 and rowData.img4.url and rowData.img4.url ~= "") then
            ImgFileName4 = rowData.img4.url:match("([^/]+)$")         
            local imgY_4 = sumY
            
            if(utils.fileExist(ImgFileName4, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName4
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_4
                    , rowData.img4.new_w
                    , rowData.img4.new_h
                    , true, 4)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_4, rowData.img4.new_w, rowData.img4.new_h)
                local requestId = 
                    network.download(
                        rowData.img4.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_4, rowData.img4.new_w, rowData.img4.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName4, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_4
                                    , rowData.img4.new_w
                                    , rowData.img4.new_h 
                                    , true, 4
                                )
                            end
                        end ,
                        ImgFileName4,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img4.new_h + contentImagePadding
        end
        
        local ImgFileName5
        if(rowData.img5 and rowData.img5.url and rowData.img5.url ~= "") then
            ImgFileName5 = rowData.img5.url:match("([^/]+)$")         
            local imgY_5 = sumY
            if(utils.fileExist(ImgFileName5, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName5
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_5
                    , rowData.img5.new_w
                    , rowData.img5.new_h
                    , true, 5)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_5, rowData.img5.new_w, rowData.img5.new_h)
                local requestId = 
                    network.download(
                        rowData.img5.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_5, rowData.img5.new_w, rowData.img5.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName5, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_5
                                    , rowData.img5.new_w
                                    , rowData.img5.new_h 
                                    , true, 5
                                )
                            end
                        end ,
                        ImgFileName5,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img5.new_h + contentImagePadding
        end
        
        local ImgFileName6
        if(rowData.img6 and rowData.img6.url and rowData.img6.url ~= "") then
            ImgFileName6 = rowData.img6.url:match("([^/]+)$")         
            local imgY_6 = sumY
--            sumY = sumY + rowData.img5.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName6, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName6
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_6
                    , rowData.img6.new_w
                    , rowData.img6.new_h
                    , true, 6)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_6, rowData.img6.new_w, rowData.img6.new_h)
                local requestId = 
                    network.download(
                        rowData.img6.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_6, rowData.img6.new_w, rowData.img6.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName6, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_6
                                    , rowData.img6.new_w
                                    , rowData.img6.new_h 
                                    , true, 6
                                )
                            end
                        end ,
                        ImgFileName6,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img6.new_h + contentImagePadding
        end
        
        local ImgFileName7
        if(rowData.img7 and rowData.img7.url and rowData.img7.url ~= "") then
            ImgFileName7 = rowData.img7.url:match("([^/]+)$")         
            local imgY_7 = sumY
--            sumY = sumY + rowData.img6.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName7, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName7
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_7
                    , rowData.img7.new_w
                    , rowData.img7.new_h
                    , true, 7)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_7, rowData.img7.new_w, rowData.img7.new_h)
                local requestId = 
                    network.download(
                        rowData.img7.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_7, rowData.img7.new_w, rowData.img7.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName7, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_7
                                    , rowData.img7.new_w
                                    , rowData.img7.new_h 
                                    , true, 7
                                )
                            end
                        end ,
                        ImgFileName7,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img7.new_h + contentImagePadding
        end
        
        local ImgFileName8
        if(rowData.img8 and rowData.img8.url and rowData.img8.url ~= "") then
            ImgFileName8 = rowData.img8.url:match("([^/]+)$")         
            local imgY_8 = sumY
--            sumY = sumY + rowData.img7.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName8, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName8
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_8
                    , rowData.img8.new_w
                    , rowData.img8.new_h
                    , true, 8)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_8, rowData.img8.new_w, rowData.img8.new_h)
                local requestId =
                    network.download(
                        rowData.img8.url,
                        "GET",
                        function(event)
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_8, rowData.img8.new_w, rowData.img8.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName8, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_8
                                    , rowData.img8.new_w
                                    , rowData.img8.new_h 
                                    , true, 8
                                )
                            end
                        end ,
                        ImgFileName8,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img8.new_h + contentImagePadding
        end
        
        local ImgFileName9
        if(rowData.img9 and rowData.img9.url and rowData.img9.url ~= "") then
            ImgFileName9 = rowData.img9.url:match("([^/]+)$")         
            local imgY_9 = sumY
--            sumY = sumY + rowData.img8.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName9, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName9
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_9
                    , rowData.img9.new_w
                    , rowData.img9.new_h
                    , true, 9)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_9, rowData.img9.new_w, rowData.img9.new_h)
                local requestId =
                    network.download(
                        rowData.img9.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_9, rowData.img9.new_w, rowData.img9.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName9, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_9
                                    , rowData.img9.new_w
                                    , rowData.img9.new_h 
                                    , true, 9
                                )
                            end
                        end ,
                        ImgFileName9,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img9.new_h + contentImagePadding
        end
        
        local ImgFileName10
        if(rowData.img10 and rowData.img10.url and rowData.img10.url ~= "") then
            ImgFileName10 = rowData.img10.url:match("([^/]+)$")         
            local imgY_10 = sumY
--            sumY = sumY + rowData.img9.new_h + contentImagePadding
            
            if(utils.fileExist(ImgFileName10, system.TemporaryDirectory) == true) then
                alignImage(row, ImgFileName10
                    , system.TemporaryDirectory
                    , imgX
                    , imgY_10
                    , rowData.img10.new_w
                    , rowData.img10.new_h
                    , true, 10)
            else
                row.tempImg = utils.imageLoadingRect(row, imgX, imgY_10, rowData.img10.new_w, rowData.img10.new_h)
                local requestId =
                    network.download(
                        rowData.img10.url,
                        "GET",
                        function(event) 
                            if ( event.isError ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                utils.imageLoadingFailedRect(row, imgX, imgY_10, rowData.img10.new_w, rowData.img10.new_h)
                            elseif ( event.phase == "ended" ) then
                                if(row.tempImg) then
                                    row.tempImg:removeSelf()
                                    row.tempImg = nil
                                end
                                alignImage(row, ImgFileName10, system.TemporaryDirectory, 
                                    imgX
                                    , imgY_10
                                    , rowData.img10.new_w
                                    , rowData.img10.new_h 
                                    , true, 10
                                )
                            end
                        end ,
                        ImgFileName10,
                        system.TemporaryDirectory
                    )
                api.insertQueue(requestId)
            end
            sumY = sumY + rowData.img10.new_h + contentImagePadding
        end
        
        local cell_width = row.viewPanel.width / 3
        row.goodButton = widget.newButton
        {
            width = 80,
            height = 30,
            defaultFile = "images/assets1/btn_like_big.png",
            overFile = "images/assets1/btn_like_big.png",
            label = language["noticeViewScene"]["good"],
            labelAlign = "right",
            labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
--            emboss = true,
            fontSize = __buttonFontSize__,
            onRelease = function(event)
                            if(event.phase == "ended") then
--                                activityIndicator = ActivityIndicator:new(language["activityIndicator"]["save"])
--                                api.plus_notice_goodcnt(message_id, user.userData.id, 
--                                    function() 
--                                        activityIndicator:destroy()
--                                        utils.showMessage(language["ViewSceneButton"]["good_save"])
--                                        somethingActionOnScene = true
--                                    end
--                                )
                            end
                        end
        }
        row.goodButton.anchorX = 0
        row.goodButton.anchorY = 0
        row.goodButton.x = row.viewPanel.x + (cell_width - row.goodButton.width)/2
        row.goodButton.y = row.viewPanel.height - row.goodButton.height
        row:insert(row.goodButton)
        
        row.addScheduleButton = widget.newButton
        {
            width = row.goodButton.width,
            height = 30,
            defaultFile = "images/assets1/btn_calendar_big.png",
            overFile = "images/assets1/btn_calendar_big.png",
            label = language["noticeViewScene"]["add_schedule"],
            labelAlign = "right",
            labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
--            emboss = true,
            fontSize = __buttonFontSize__,
            onRelease = nil
        }
        row.addScheduleButton.anchorX = 0
        row.addScheduleButton.anchorY = 0
        row.addScheduleButton.x = cell_width + row.goodButton.x
        row.addScheduleButton.y = row.goodButton.y
        row:insert(row.addScheduleButton)
        
        row.okButton = widget.newButton
        {
            width = row.addScheduleButton.width,
            height = 30,
            defaultFile = "images/assets1/btn_ok_big.png",
            overFile = "images/assets1/btn_ok_big.png",
            label = language["messageViewScene"]["ok"],
            labelAlign = "right",
            labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
--            emboss = true,
            fontSize = __buttonFontSize__,
            onRelease = function(event)
                            if(event.phase == "ended") then
                                if utils.IS_Demo_mode(storyboard, true) == true then
                                    return true
                                end
                                
                                activityIndicator = ActivityIndicator:new(language["activityIndicator"]["save"])
                                api.send_conatct_read2(message_id, user.userData.id, user.getActiveKid_IDByAuthority(), 
                                    function(e) 
                                        if (activityIndicator) then
                                            activityIndicator:destroy()
                                        end
                                        
                                        if ( e.isError ) then
                                            utils.showMessage(language["common"]["wrong_connection"])
                                        else
                                            if(e.status == 200) then
                                                utils.showMessage(language["ViewSceneButton"]["confirm_save"])
                                                oData.needRefresh = true
                                                oData.readyn = "1"
                                    
                                                row.okButton.isVisible = false
                                            else
                                                utils.showMessage(language["common"]["wrong_connection"])
                                            end
                                        end    
                                    end
                                )
                            end
                        end
        }
        row.okButton.anchorX = 0
        row.okButton.anchorY = 0
        row.okButton.x = cell_width + row.addScheduleButton.x
        row.okButton.y = row.addScheduleButton.y
        row:insert(row.okButton)
        
        local readCount_txt = rowData.target.read_cnt.."/"..rowData.target.total_cnt
        row.readCount = display.newText(readCount_txt, 12, 0, native.systemFontBold, 12)
        row.readCount.anchorX = 0
        row.readCount.anchorY = 0
        row.readCount:setFillColor( 0.375, 0.375, 0.375 )
        row.readCount.y = row.okButton.y + (row.okButton.height - row.readCount.height)/2
        row.readCount.x = row.okButton.x - row.readCount.width - 5
        row:insert(row.readCount)
        
        row.notReadListButton = widget.newButton --연락장 안읽은 사람 확인 용(원장, 선생만 가능)
        {
            width = row.addScheduleButton.width,
            height = 30,
            defaultFile = "images/assets1/btn_ok_big.png",
            overFile = "images/assets1/btn_ok_big.png",
            label = language["messageViewScene"]["ok"],
            labelAlign = "right",
            labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
--            emboss = true,
            fontSize = __buttonFontSize__,
            onRelease = function(event)
                            if(event.phase == "ended") then
                                local options = {
                                    effect = "fromRight",
                                    time = 300,
                                    params = {
                                        thread_type = __MESSAGE_THREAD_TYPE__,
                                        thread_id = message_id,
                                        thread_title = "",
                                        thread_total_cnt = rowData.target.total_cnt,
                                        thread_read_cnt = rowData.target.read_cnt,
                                        previous_scene = "scripts.messageViewScene"
                                    }
                                }
                                storyboard.purgeScene("scripts.notReadList4MessageScene")
                                storyboard.gotoScene("scripts.notReadList4MessageScene", options)
                            end
                        end
        }
        row.notReadListButton.anchorX = 0
        row.notReadListButton.anchorY = 0
        row.notReadListButton.x = cell_width + row.addScheduleButton.x
        row.notReadListButton.y = row.addScheduleButton.y
        row:insert(row.notReadListButton)
        
        row.goodButton.isVisible = false
        row.addScheduleButton.isVisible = false
        row.readCount.isVisible = false
        row.okButton.isVisible = false
        row.notReadListButton.isVisible = false
        
        if(user.userData.jobType == __PARENT__) then
            if(rowData.type == __MESSAGE_FROM_CENTER__ and rowData.readyn == "0") then
                row.okButton.isVisible = true
            end
        else
            if(rowData.type == __MESSAGE_FROM_HOME__) then --가정에서 온 메세지
                if (rowData.readyn == "0") then
                    row.okButton.isVisible = true
                end
            else
                row.readCount.isVisible = true  --원에서 보낸 메세지
                row.notReadListButton.isVisible = true
            end
        end
    end
    
    if(rowData) and(index > 2)  then
        row.commentRect = display.newRoundedRect(row.width/2, row.height/2, row.width- 5, row.height - 4, 6)
        row.commentRect.anchorX= 0
        row.commentRect.anchorY = 0
        row.commentRect.x = (row.width - row.commentRect.width) /2
        row.commentRect.y = 0
        row:insert(row.commentRect)
        
        local writerImgFileName
        if(rowData.member_img) then
            writerImgFileName = rowData.member_img:match("([^/]+)$")         
        end
            
        local imageWidth = 30
        local imageHeight = 30
        if(writerImgFileName) then
            if(utils.fileExist(writerImgFileName, system.TemporaryDirectory) == true) then
                alignImage(row, writerImgFileName, system.TemporaryDirectory, LEFT_PADDING, COMMENT_TOP_PADDING, imageWidth, imageHeight)    
            else
                network.download(
                    rowData.member_img,
                    "GET",
                    function(event) 
                        if ( event.isError ) then
                            alignImage(row, "images/assets1/pic_photo_30x30.png", nil, LEFT_PADDING, COMMENT_TOP_PADDING, imageWidth, imageHeight) 
                        elseif ( event.phase == "ended" ) then
                            alignImage(row, writerImgFileName, system.TemporaryDirectory, LEFT_PADDING, COMMENT_TOP_PADDING, imageWidth, imageHeight)
                        end
                    end ,
                    writerImgFileName,
                    system.TemporaryDirectory
                )
            end
        else
        --      default image  
            writerImgFileName = "images/assets1/pic_photo_80x80.png"
            alignImage(row, writerImgFileName, nil, LEFT_PADDING, COMMENT_TOP_PADDING, imageWidth, imageHeight)
        end
        
        local memberName_txt_options = 
        {
            text = rowData.member_name..user.getCallNameByMemberType(rowData.member_type),
            width = row.width - LEFT_PADDING - imageWidth,
            font = native.systemFontBold,   
            fontSize = 10,
            align = "left",  --new alignment parameter
        }
        row.txt_member_name = display.newText(memberName_txt_options)
        row.txt_member_name:setFillColor(unpack(__Read_NoticeList_FontColor__))
        row.txt_member_name.anchorX = 0
        row.txt_member_name.anchorY = 0
        row.txt_member_name.x = imageWidth + LEFT_PADDING + 6
        row.txt_member_name.y = COMMENT_TOP_PADDING
        row:insert(row.txt_member_name)
            
        local comment_createTime_txt_options = 
        {
            text = utils.getTimeStamp(rowData.createtime), --rowData.createtime,
--            width = row.width - LEFT_PADDING - imageWidth,
            font = native.systemFont,   
            fontSize = 10,
            align = "left",  --new alignment parameter
        }
        row.txt_comment_createTime = display.newText(comment_createTime_txt_options)
        row.txt_comment_createTime:setFillColor(unpack(__Read_NoticeList_FontColor__))
        row.txt_comment_createTime.anchorX = 0
        row.txt_comment_createTime.anchorY = 0
        row.txt_comment_createTime.x = row.width - row.txt_comment_createTime.width - LEFT_PADDING - 10
        row.txt_comment_createTime.y = COMMENT_TOP_PADDING
        row:insert(row.txt_comment_createTime)
            
        local delete_button_size = 20 
        local comment_txt_options = 
        {
            text = rowData.contents,     
            width = row.width - (row.txt_member_name.x + delete_button_size + 20),-- 260,--row.width - LEFT_PADDING - imageWidth - 10,
            font = native.systemFont,   
            fontSize = __COMMENT_FONT_SIZE__,
            align = "left",  --new alignment parameter
        }
        row.txt_comment = display.newText(comment_txt_options)
        row.txt_comment.anchorX = 0
        row.txt_comment.anchorY = 0
        row.txt_comment.x = row.txt_member_name.x 
        row.txt_comment.y = COMMENT_TOP_PADDING + row.txt_member_name.height + 4
        row.txt_comment:setFillColor(unpack(__Read_NoticeList_FontColor__))
        row:insert(row.txt_comment) 
        
        local yOffset = row.txt_comment.y + row.txt_comment.height + 5
        local urlTable = utils.getURLfromContents(rowData.contents)
        for i = 1, #urlTable do
            comment_txt_options.text = urlTable[i]
            
            local url_text = display.newText(comment_txt_options)
            url_text.anchorX = 0
            url_text.anchorY = 0
            url_text.x = row.txt_comment.x
            url_text.y = yOffset + 5
            row:insert(url_text)
            url_text:setFillColor( unpack( __URL_LINK_COLOR__ ))
            yOffset = yOffset + url_text.height + 5

            url_text:addEventListener("tap", 
                function()
                    system.openURL( urlTable[i] )
                end
            )
        end
        
--        if(rowData.member_id == user.userData.id) then --연락장 덧글 삭제 기능을 삭제
--            row.deleteButton = widget.newButton
--            {
--                width = 16,
--                height = 16,
--                defaultFile = "images/assets1/icon_delete.png",
--                overFile = "images/assets1/icon_delete.png",
--                onRelease = function(event)
--                                if(event.phase == "ended") then
--                                    if utils.IS_Demo_mode(storyboard, true) == true then
--                                        return true
--                                    end
--                                    
--                                    native.showAlert(language["appTitle"], language["messageViewScene"]["delete_comment"], 
--                                        { language["messageViewScene"]["yes"], language["messageViewScene"]["no"] }, 
--                                        function(event)
--                                            if "clicked" == event.action then
--                                                local i = event.index
--                                                if 1 == i then
--                                                    activityIndicator = ActivityIndicator:new(language["activityIndicator"]["delete"])
--                                                    api.delete_contact_reply(rowData.contact_id, rowData.reply_id, 
--                                                        function(e)
--                                                            oData.needRefresh = true
--                                                            activityIndicator:destroy()
--                                                            
--                                                            msgTable._view._velocity = 0
--                                                            msgTable:deleteRow(index)
--                                                        end
--                                                    )
--                                                end
--                                            end    
--                                        end
--                                    )
--                                end
--                            end
--            }
--            row.deleteButton.anchorX = 0
--            row.deleteButton.anchorY = 0
--            row.deleteButton.x = row.width - row.deleteButton.width - LEFT_PADDING - 10
--            row.deleteButton.y = row.txt_comment_createTime.y + row.txt_comment_createTime.height + 1
--            row:insert(row.deleteButton)
--        end
    end
end
	
local function getCommentDataCallback(event)
    local function makeRow(json_data)
        if(msgTable) then
            local cnt = json_data.reply_cnt
            if(cnt > 0) then
                if (firstCommentID) then
                    if(tonumber(firstCommentID) == tonumber(json_data.reply[1].reply_id)) then
                        --새로운 내용이 없음
                        return true 
                    elseif(tonumber(firstCommentID) > tonumber(json_data.reply[1].reply_id)) then
                        --과거 데이터 가져옴
                        for i = 1, cnt do
                            local reply_data = json_data.reply[i]
                            local commentHeight = getHeightofString(reply_data.contents, 260, native.systemFont, __COMMENT_FONT_SIZE__)
                            msgTable:insertRow{
                                rowHeight = commentHeight + 40,
                                rowColor = {  default = { 1, 1, 1, 0 }, over = {1, 1, 1, 0}},
--                                lineColor = { 0.5, 0.5, 0.5 },
                                params = { rowData = reply_data}
                            }
                        end
                        return true
                    else
                        --새로운 데이타 있음
                        msgTable:deleteAllRows()     
                        
                        displayView()
                        
                        firstCommentID = json_data.reply[1].reply_id
                        for i = 1, cnt do
                            local reply_data = json_data.reply[i]
                            local commentHeight = getHeightofString(reply_data.contents, 260, native.systemFont, __COMMENT_FONT_SIZE__)
                            msgTable:insertRow{
                                rowHeight = commentHeight + 40,
                                rowColor = {  default = { 1, 1, 1, 0 }, over = {1, 1, 1, 0}},
--                                lineColor = { 0.5, 0.5, 0.5 },
                                params = { rowData = reply_data}
                            }
                        end    
                    end
                else
                    firstCommentID = json_data.reply[1].reply_id
                    for i = 1, cnt do
                        local reply_data = json_data.reply[i]
                        local commentHeight = getHeightofString(reply_data.contents, 260, native.systemFont, __COMMENT_FONT_SIZE__)
                        msgTable:insertRow{
                            rowHeight = commentHeight + 40,
                            rowColor = {  default = { 1, 1, 1, 0 }, over = {1, 1, 1, 0}},
--                            lineColor = { 0.5, 0.5, 0.5 },
                            params = { rowData = reply_data}
                        }
                    end
                end        
            end
        end
        
        return
    end
    
    if(activityIndicator) then
        activityIndicator:destroy()
    end
    if ( event.isError ) then
        utils.showMessage(language["common"]["wrong_connection"])
    else
        if(event.status == 200) then
            local data = json.decode(event.response)
        
            if (data) then
                if(data.status == "OK") then
                    makeRow(data)
                else
                    utils.showMessage(language["common"]["wrong_connection"])
                end
            end
        end
    end
    
    return true
end

local function scrollListener( event )
    if (reloadInProgress == true) then
        return true
    end
       
    if ( event.phase == "began" ) then
        needToReload = false
        needToPastload = false
        
        springStart = msgTable:getContentPosition( )
    elseif ( event.phase == "moved") then
        if (msgTable:getContentPosition( ) > springStart + REFRESH_ROW_HEIGHT) then
            needToReload = true
            transition.to( pullDown, { time=100, rotation=180 } )
        end    
        
        if (msgTable:getContentPosition( ) < springStart - (REFRESH_ROW_HEIGHT * 0.5)) then
            needToPastload = true
        end
    elseif ( event.limitReached == true and event.phase == nil and  event.direction == "down" and needToReload == true ) then
        reloadInProgress = true  --turn this off at the end of the reload function
        needToReload = false
	if(pullDown) then
            pullDown.alpha = 0
        end
	reloadspinner.alpha = 1
        reloadspinner:start()              
        
        pageno = 1
        api.get_contact_reply_list2(message_id, user.userData.id, pageno, pagesize, getCommentDataCallback)
        
        reloadTable() 
    elseif ( event.limitReached == true and event.phase == nil and  event.direction == "up" and needToPastload == true) then    
        needToPastload = false
        
        pageno = pageno + 1
       api.get_contact_reply_list2(message_id, user.userData.id, pageno, pagesize, getCommentDataCallback)
   end 
end

local function onLeftButton(event)
    if event.phase == "ended" then
        if(oData.needRefresh == true) then
            storyboard.purgeScene("scripts.messageScene")
        end
        storyboard.gotoScene("scripts.messageScene", "slideRight", 300)
    end
    
    return true
end

local function onRightButton(event)
    if event.phase == "ended" then -- 삭제
        if utils.IS_Demo_mode(storyboard, true) == true then
            return true
        end
        
        if(user.userData.jobType ~= __DIRECTOR__)then
            if(oData.writer.id ~= user.userData.id) then
                utils.showMessage(language["messageViewScene"]["authority_delete"])
                return true
            end
        end
        
        native.showAlert(language["appTitle"], language["messageViewScene"]["delete_question"], 
            { language["messageViewScene"]["yes"],language["messageViewScene"]["no"] },  
            function(event) 
                if "clicked" == event.action then
                    local i = event.index
                    if 1 == i then
                        activityIndicator = ActivityIndicator:new(language["activityIndicator"]["delete"])
                        api.delete_contact(message_id, 
                            function(event) 
                                activityIndicator:destroy()
                                storyboard.purgeScene("scripts.messageScene")
                                storyboard.gotoScene("scripts.messageScene", "slideRight", 300)
                            end
                        )
                    end
                end    
            end
        )
    end
    
    return true
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view
    imageGroup = display.newGroup()
    
    photolist = {}
--    rowData = event.params.rowData
    oData = sceneData.getSceneData("scripts.messageScene", "scripts.messageViewScene")
    message_id = oData.id
    if(not oData.needRefresh) then
        oData.needRefresh = false
    end 
    
    local bg = display.newImageRect(group, "images/bg_set/bg_sub.png", __backgroundWidth__, __backgroundHeight__)
    bg.x = display.contentWidth / 2
    bg.y = display.contentHeight / 2
    group:insert(bg)
    
    local table_group = display.newGroup()
    msgTable = widget.newTableView{
        top = __statusBarHeight__ + NAVI_BAR_HEIGHT + NAME_BAR_HEIGHT - REFRESH_ROW_HEIGHT,
	height = __appContentHeight__ - (NAVI_BAR_HEIGHT - REFRESH_ROW_HEIGHT) - NAME_BAR_HEIGHT - __statusBarHeight__ - COMMENT_BOX_HEIGHT,
        width = __appContentWidth__ ,
	maxVelocity = 1, 
        noLines = true,
        hideBackground = true,    
	onRowRender = onRowRender,
--	onRowTouch = nil,--onRowTouch,
	listener = scrollListener
    }
    msgTable.x = display.contentWidth / 2
    table_group:insert(msgTable)
    group:insert(table_group)
    
    local btn_left_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__},
        label = language["messageViewScene"]["back"],
        onEvent = onLeftButton,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        width = 100,
        height = 50,
        defaultFile = "images/top_with_texts/btn_top_text_back_normal.png",
        overFile = "images/top_with_texts/btn_top_text_back_touched.png",    
    }

    local btn_right_opt = {
        labelColor = { default = __NAVBAR_BUTTON_COLOR__, over = __NAVBAR_BUTTON_COLOR__},
        label = language["messageViewScene"]["delete"],
        onEvent = onRightButton,
        font = native.systemFont,
        fontSize = __buttonFontSize__,
        width = 100,
        height = 50,
        defaultFile = "images/top_with_texts/btn_top_text_delete_normal.png",
        overFile = "images/top_with_texts/btn_top_text_delete_touched.png",    
    }
    
    local navBar = widget.newNavigationBar({
        title = language["messageViewScene"]["title"],
        width = __appContentWidth__,
        background = "images/top/bg_top.png",
        titleColor = __NAVBAR_TXT_COLOR__,
        font = native.systemFontBold,
        fontSize = __navBarTitleFontSize__,
        leftButton = btn_left_opt,
        rightButton = btn_right_opt,
--        includeStatusBar = false
    })
       
    navBar:addEventListener("touch", function() return true end)
    group:insert(navBar)
    
    local nameRect = display.newRect(group, display.contentCenterX, __statusBarHeight__ + 65, __appContentWidth__, NAME_BAR_HEIGHT )
    nameRect.strokeWidth = 0
    nameRect:setFillColor( 1, 0 ,0 )
    nameRect:setStrokeColor( 0, 0, 0)
    nameRect:addEventListener("tap", function() return true end)
    
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
    
    local function onComment_box_Handler(event)
        if event.phase == "ended" then
            local params = {
                comment_type = "message",
                rowData = oData
            }
            local options = {
                effect = "fromBottom",
                time = 300,
                params = params
            }
            storyboard.purgeScene("scripts.commentScene")
            storyboard.gotoScene("scripts.commentScene", options)
        end
        
--        return true
    end
            
    local comment_box = display.newRect(group, display.contentCenterX, 0, __appContentWidth__, 40)
--    comment_box.anchorX = 0
    comment_box:setFillColor(1, 1, 1)
    comment_box.x = display.contentCenterX
    comment_box.y = __appContentHeight__ - comment_box.height/2
    comment_box.width = __appContentWidth__
    group:insert(comment_box)
    
    comment_box:addEventListener("touch", onComment_box_Handler)
    
    local default_comment_text = display.newText(group, language["messageViewScene"]["input_comment"], 0, 0, __appContentWidth__ - 50, 30, native.systemFont, 12)
    default_comment_text.anchorX = 0
    default_comment_text:setFillColor(0, 0, 0, 0.7)
    default_comment_text.x = 10
    default_comment_text.y = __appContentHeight__ - default_comment_text.height/2
    group:insert(default_comment_text)
    
    displayView()
    
--    activityIndicator = ActivityIndicator:new(language["activityIndicator"]["getdata"])
    api.get_contact_reply_list2(message_id, user.userData.id, pageno, pagesize, getCommentDataCallback)
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
    local group = self.view
    
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view
--    imageGroup = display.newGroup()
    storyboard.isAction = false
    storyboard.returnTo = "scripts.messageScene"
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
    local group = self.view
    
    api.cancelRequest()
end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene( event )
    local group = self.view
    
end

-- Called prior to the removal of scene's "view" (display view)
function scene:destroyScene( event )
    local group = self.view
    
    pageno = 1
    firstCommentID = nil
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

