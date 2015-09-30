@getBuildInformation = ->
  copyrightYear = Meteor.config?.copyrightYear or "DATE"
  html5ClientBuild = Meteor.config?.html5ClientBuild or "VERSION"
  defaultWelcomeMessage = Meteor.config?.defaultWelcomeMessage or "WELCOME MESSAGE"
  defaultWelcomeMessageFooter = Meteor.config?.defaultWelcomeMessageFooter or "WELCOME MESSAGE"
  link = "<a href='http://bigbluebutton.org/' target='_blank'>http://bigbluebutton.org</a>"

  {
    'copyrightYear': copyrightYear
    'html5ClientBuild': html5ClientBuild
    'defaultWelcomeMessage': defaultWelcomeMessage
    'defaultWelcomeMessageFooter': defaultWelcomeMessageFooter
    'link': link
  }

# Convert a color `value` as integer to a hex color (e.g. 255 to #0000ff)
@colourToHex = (value) ->
  hex = parseInt(value).toString(16)
  hex = "0" + hex while hex.length < 6
  "##{hex}"

# color can be a number (a hex converted to int) or a string (e.g. "#ffff00")
@formatColor = (color) ->
  color ?= "0" # default value
  if !color.toString().match(/\#.*/)
    color = colourToHex(color)
  color

@getCurrentSlideDoc = -> # returns only one document
  BBB.getCurrentSlide()

@getInSession = (k) -> SessionAmplify.get k

@getTime = -> # returns epoch in ms
  (new Date).valueOf()

# checks if the pan gesture is mostly horizontal
@isPanHorizontal = (event) ->
  Math.abs(event.deltaX) > Math.abs(event.deltaY)

# helper to determine whether user has joined any type of audio
Handlebars.registerHelper "amIInAudio", ->
  BBB.amIInAudio()

# helper to determine whether the user is in the listen only audio stream
Handlebars.registerHelper "amIListenOnlyAudio", ->
  BBB.amIListenOnlyAudio()

Handlebars.registerHelper "colourToHex", (value) =>
  @window.colourToHex(value)

Handlebars.registerHelper 'equals', (a, b) -> # equals operator was dropped in Meteor's migration from Handlebars to Spacebars
  a is b

Handlebars.registerHelper "getCurrentMeeting", ->
  Meteor.Meetings.findOne()

Handlebars.registerHelper "getCurrentSlide", ->
  currentPresentation = Meteor.Presentations.findOne({"presentation.current": true})
  presentationId = currentPresentation?.presentation?.id
  Meteor.Slides.find({"presentationId": presentationId, "slide.current": true})

# Allow access through all templates
Handlebars.registerHelper "getInSession", (k) -> SessionAmplify.get k

Handlebars.registerHelper "getMeetingName", ->
  BBB.getMeetingName()

Handlebars.registerHelper "getShapesForSlide", ->
  currentSlide = getCurrentSlideDoc()

  # try to reuse the lines above
  Meteor.Shapes.find({whiteboardId: currentSlide?.slide?.id})

# retrieves all users in the meeting
Handlebars.registerHelper "getUsersInMeeting", ->
  users = Meteor.Users.find().fetch()
  if users?.length > 1
    getSortedUserList(users)
  else
    users

Handlebars.registerHelper "getWhiteboardTitle", ->
  (BBB.currentPresentationName() or "Loading presentation...")

Handlebars.registerHelper "isCurrentUser", (userId) ->
  userId is null or userId is BBB.getCurrentUser()?.userId

Handlebars.registerHelper "isCurrentUserMuted", ->
  BBB.amIMuted()

#Retreives a username for a private chat tab from the database if it exists
Handlebars.registerHelper "privateChatName", ->
  obj = Meteor.Users.findOne({ userId: getInSession "inChatWith" })
  if obj?
    obj?.user?.name

Handlebars.registerHelper "isCurrentUserRaisingHand", ->
  BBB.isCurrentUserRaisingHand()

Handlebars.registerHelper "isCurrentUserSharingVideo", ->
  BBB.amISharingVideo()

Handlebars.registerHelper "isCurrentUserTalking", ->
  BBB.amITalking()

Handlebars.registerHelper "isCurrentUserPresenter", ->
  BBB.isUserPresenter(getInSession('userId'))

Handlebars.registerHelper "isDisconnected", ->
  return !Meteor.status().connected

Handlebars.registerHelper "isUserInAudio", (userId) ->
  BBB.isUserInAudio(userId)

Handlebars.registerHelper "isUserListenOnlyAudio", (userId) ->
  BBB.isUserListenOnlyAudio(userId)

Handlebars.registerHelper "isUserMuted", (userId) ->
  BBB.isUserMuted(userId)

Handlebars.registerHelper "isUserSharingVideo", (userId) ->
  BBB.isUserSharingWebcam(userId)

Handlebars.registerHelper "isUserTalking", (userId) ->
  BBB.isUserTalking(userId)

Handlebars.registerHelper 'isMobile', () ->
  isMobile()

Handlebars.registerHelper 'isPortraitMobile', () ->
  isPortraitMobile()

Handlebars.registerHelper 'isMobileChromeOrFirefox', () ->
  isMobile() and ((getBrowserName() is 'Chrome') or (getBrowserName() is 'Firefox'))

Handlebars.registerHelper "meetingIsRecording", ->
  BBB.isMeetingRecording()

Handlebars.registerHelper "messageFontSize", ->
  style: "font-size: #{getInSession("messageFontSize")}px;"

Handlebars.registerHelper "pointerLocation", ->
  currentPresentation = Meteor.Presentations.findOne({"presentation.current": true})
  presentationId = currentPresentation?.presentation?.id
  currentSlideDoc = Meteor.Slides.findOne({"presentationId": presentationId, "slide.current": true})
  pointer = currentPresentation?.pointer
  pointer.x = (- currentSlideDoc.slide.x_offset * 2 + currentSlideDoc.slide.width_ratio * pointer.x) / 100
  pointer.y = (- currentSlideDoc.slide.y_offset * 2 + currentSlideDoc.slide.height_ratio * pointer.y) / 100
  pointer

Handlebars.registerHelper "safeName", (str) ->
  safeString(str)

###Handlebars.registerHelper "visibility", (section) ->
  if getInSession "display_#{section}"
    style: 'display:block;'
  else
    style: 'display:none;'###

Handlebars.registerHelper "visibility", (section) ->
  style: 'display:block;'

Handlebars.registerHelper 'containerPosition', (section) ->
  if getInSession 'display_usersList'
    return 'moved-to-right'
  else if getInSession 'display_menu'
    return 'moved-to-left'
  else
    return ''

# vertically shrinks the whiteboard if the slide navigation controllers are present
Handlebars.registerHelper 'whiteboardSize', (section) ->
  if BBB.isUserPresenter(getInSession('userId'))
    return 'presenter-whiteboard'
  else
    if BBB.isPollGoing(getInSession('userId'))
      return 'poll-whiteboard'
    else
      return 'viewer-whiteboard'

Handlebars.registerHelper "getPollQuestions", ->
  polls = BBB.getCurrentPoll(getInSession('userId'))
  if polls? and polls isnt undefined
    number = polls.poll_info.poll.answers.length
    widthStyle = "width: calc(75%/" + number + ");"
    marginStyle = "margin-left: calc(25%/" + (number*2) + ");" + "margin-right: calc(25%/" + (number*2) + ");"
    buttonStyle = widthStyle + marginStyle
    for answer in polls.poll_info.poll.answers
      answer.style = buttonStyle
    return polls.poll_info.poll.answers

@getSortedUserList = (users) ->
  if users?.length > 1
    users.sort (a, b) ->
      if a.user.role is "MODERATOR" and b.user.role is "MODERATOR"
        if a.user.raise_hand and b.user.raise_hand
          aTime = a.user.raise_hand.getTime()
          bTime = b.user.raise_hand.getTime()
          if aTime < bTime
            return -1
          else
            return 1
        else if a.user.raise_hand
          return -1
        else if b.user.raise_hand
          return 1
      else if a.user.role is "MODERATOR"
        return -1
      else if b.user.role is "MODERATOR"
        return 1
      else if a.user.raise_hand and b.user.raise_hand
        aTime = a.user.raise_hand.getTime()
        bTime = b.user.raise_hand.getTime()
        if aTime < bTime
          return -1
        else
          return 1
      else if a.user.raise_hand
        return -1
      else if b.user.raise_hand
        return 1
      else if not a.user.phone_user and not b.user.phone_user

      else if not a.user.phone_user
        return -1
      else if not b.user.phone_user
        return 1

      #Check name (case-insensitive) in the event of a tie up above. If the name
      #is the same then use userID which should be unique making the order the same
      #across all clients.

      if a.user._sort_name < b.user._sort_name
        return -1
      else if a.user._sort_name > b.user._sort_name
        return 1
      else if a.user.userid.toLowerCase() > b.user.userid.toLowerCase()
        return -1
      else if a.user.userid.toLowerCase() < b.user.userid.toLowerCase()
        return 1

  users

# transform plain text links into HTML tags compatible with Flash client
@linkify = (str) ->
  str = str.replace re_weburl, "<a href='event:$&'><u>$&</u></a>"

@setInSession = (k, v) -> SessionAmplify.set k, v

@safeString = (str) ->
  if typeof str is 'string'
    str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

@toggleCam = (event) ->
  # Meteor.Users.update {_id: context._id} , {$set:{"user.sharingVideo": !context.sharingVideo}}
  # Meteor.call('userToggleCam', context._id, !context.sharingVideo)

@toggleChatbar = ->
  setInSession "display_chatbar", !getInSession "display_chatbar"
  if !getInSession("display_chatbar")
    $('#whiteboard').css('width', '100%')
    $('#whiteboard .ui-resizable-handle').css('display', 'none')
  else
    $('#whiteboard').css('width', '')
    $('#whiteboard .ui-resizable-handle').css('display', '')
  setTimeout(scaleWhiteboard, 0)

@toggleMic = (event) ->
  BBB.toggleMyMic()

@toggleUsersList = ->
  if $('.sl-left-drawer').hasClass('hiddenInLandscape')
    $('.sl-left-drawer').removeClass('hiddenInLandscape')
  else
    $('.sl-left-drawer').addClass('hiddenInLandscape')
  setTimeout(scaleWhiteboard, 0)

@populateNotifications = (msg) ->
  myUserId = getInSession "userId"
  users = Meteor.Users.find().fetch()

  # assuming that I only have access only to private messages where I am the sender or the recipient
  myPrivateChats = Meteor.Chat.find({'message.chat_type': 'PRIVATE_CHAT'}).fetch()

  uniqueArray = []
  for chat in myPrivateChats
    if chat.message.to_userid is myUserId
      uniqueArray.push({userId: chat.message.from_userid, username: chat.message.from_username})
    if chat.message.from_userid is myUserId
      uniqueArray.push({userId: chat.message.to_userid, username: chat.message.to_username})

  #keep unique entries only
  uniqueArray = uniqueArray.filter((itm, i, a) ->
      i is a.indexOf(itm)
    )

  if msg.message.to_userid is myUserId
    new_msg_userid = msg.message.from_userid
  if msg.message.from_userid is myUserId
    new_msg_userid = msg.message.to_userid

  chats = getInSession('chats')
  if chats is undefined
    initChats = [
      userId: "PUBLIC_CHAT"
      gotMail: false
      number: 0;
    ]
    setInSession 'chats', initChats

  #insert the unique entries in the collection
  for u in uniqueArray
    chats = getInSession('chats')
    if chats.filter((chat) -> chat.userId == u.userId).length is 0 and u.userId is new_msg_userid
      chats.push {userId: u.userId, gotMail: false, number: 0}
      setInSession 'chats', chats

@toggleShield = ->
  if parseFloat($('.shield').css('opacity')) is 0.5 # triggered during a pan gesture
    $('.shield').css('opacity', '')

  if !$('.shield').hasClass('darken') and !$('.shield').hasClass('animatedShield')
    $('.shield').addClass('darken')
  else
    $('.shield').removeClass('darken')
    $('.shield').removeClass('animatedShield')

@removeFullscreenStyles = ->
  $('#whiteboard-paper').removeClass('verticallyCentered')
  $('#chat').removeClass('invisible')
  $('#users').removeClass('invisible')
  $('#navbar').removeClass('invisible')
  $('.fullscreenButton').removeClass('exitFullscreenButton')
  $('.fullscreenButton').addClass('whiteboardFullscreenButton')
  $('.fullscreenButton i').removeClass('ion-arrow-shrink')
  $('.fullscreenButton i').addClass('ion-arrow-expand')

@enterWhiteboardFullscreen = ->
  element = document.getElementById('whiteboard')
  if element.requestFullscreen
    element.requestFullscreen()
  else if element.mozRequestFullScreen
    element.mozRequestFullScreen()
    $('.fullscreenButton').addClass('iconFirefox') # browser-specific icon sizing
  else if element.webkitRequestFullscreen
    element.webkitRequestFullscreen()
    $('.fullscreenButton').addClass('iconChrome') # browser-specific icon sizing
  else if element.msRequestFullscreen
    element.msRequestFullscreen()
  $('#chat').addClass('invisible')
  $('#users').addClass('invisible')
  $('#navbar').addClass('invisible')
  $('.fullscreenButton').removeClass('whiteboardFullscreenButton')
  $('.fullscreenButton').addClass('exitFullscreenButton')
  $('.fullscreenButton i').removeClass('ion-arrow-expand')
  $('.fullscreenButton i').addClass('ion-arrow-shrink')
  $('#whiteboard-paper').addClass('verticallyCentered')
  $('#whiteboard').bind 'webkitfullscreenchange', (e) ->
    if document.webkitFullscreenElement is null
      $('#whiteboard').unbind('webkitfullscreenchange')
      $('.fullscreenButton').removeClass('iconChrome')
      removeFullscreenStyles()
      scaleWhiteboard()
  $(document).bind 'mozfullscreenchange', (e) -> # target is always the document in Firefox
    if document.mozFullScreenElement is null
      $(document).unbind('mozfullscreenchange')
      $('.fullscreenButton').removeClass('iconFirefox')
      removeFullscreenStyles()
      scaleWhiteboard()

@closeMenus = ->
  if $('.sl-left-drawer').hasClass('sl-left-drawer-out')
    toggleLeftDrawer()
    toggleLeftArrowClockwise()
  else if $('.sl-right-drawer').hasClass('sl-right-drawer-out')
    toggleRightDrawer()
    toggleRightArrowClockwise()

# Starts the entire logout procedure.
# meeting: the meeting the user is in
# the user's userId
@userLogout = (meeting, user) ->
  Meteor.call("userLogout", meeting, user, getInSession("authToken"))
  console.log "logging out"
  clearSessionVar(document.location = getInSession 'logoutURL') # navigate to logout

# Clear the local user session
@clearSessionVar = (callback) ->
  amplify.store('authToken', null)
  amplify.store('bbbServerVersion', null)
  amplify.store('chats', null)
  amplify.store('dateOfBuild', null)
  amplify.store('display_chatPane', null)
  amplify.store('display_chatbar', null)
  amplify.store('display_navbar', null)
  amplify.store('display_usersList', null)
  amplify.store('display_whiteboard', null)
  amplify.store('inChatWith', null)
  amplify.store('logoutURL', null)
  amplify.store('meetingId', null)
  amplify.store('messageFontSize', null)
  amplify.store('tabsRenderedTime', null)
  amplify.store('userId', null)
  amplify.store('userName', null)
  amplify.store('display_menu', null)
  if callback?
    callback()

# assign the default values for the Session vars
@setDefaultSettings = ->
  setInSession "display_navbar", true
  setInSession "display_chatbar", true
  setInSession "display_whiteboard", true
  setInSession "display_chatPane", true

  #if it is a desktop version of the client
  if isPortraitMobile() or isLandscapeMobile()
    setInSession "messageFontSize", Meteor.config.app.mobileFont
  #if this is a mobile version of the client
  else
    setInSession "messageFontSize", Meteor.config.app.desktopFont
  setInSession 'display_slidingMenu', false
  setInSession 'display_hiddenNavbarSection', false
  if isLandscape()
    setInSession 'display_usersList', true
  else
    setInSession 'display_usersList', false
  setInSession 'display_menu', false
  setInSession 'chatInputMinHeight', 0

  #keep notifications and an opened private chat tab if page was refreshed
  #reset to default if that's a new user
  if loginOrRefresh()
    initChats = [
      userId: "PUBLIC_CHAT"
      gotMail: false
      number: 0
    ]
    setInSession 'chats', initChats
    setInSession "inChatWith", 'PUBLIC_CHAT'

  TimeSync.loggingEnabled = false # suppresses the log messages from timesync

#true if it is a new user, false if the client was just refreshed
@loginOrRefresh = ->
  userId = getInSession 'userId'
  checkId = getInSession 'checkId'
  if checkId is undefined
    setInSession 'checkId', userId
    return true
  else if userId isnt checkId
    setInSession 'checkId', userId
    return true
  else
    return false

@onLoadComplete = ->
    document.title = "BigBlueButton #{BBB.getMeetingName() ? 'HTML5'}"
    setDefaultSettings()

    Meteor.Users.find().observe({
    removed: (oldDocument) ->
        if oldDocument.userId is getInSession 'userId'
            document.location = getInSession 'logoutURL'
    })

    # when the meeting information has been updated check to see if it was
    # desksharing. If it has changed either trigger a call to receive video
    # and display it, or end the call and hide the video
    Meteor.Meetings.find().observe
        changed: (newDocument, oldDocument) ->
            console.log "Meeting information has been modified"
            console.log "#{newDocument}"
            if oldDocument.deskshare isnt newDocument.deskshare and newDocument.deskshare.startedBy isnt getInSession("userId")
                console.log "Deskshare was started by: #{newDocument.deskshare.startedBy}"
                console.log "you are: #{getInSession('userId')}"
                if newDocument.deskshare.broadcasting
                    console.log "Deskshare is now broadcasting"
                    presenterDeskshareHasStarted()
                else
                    console.log "Deskshare broadcasting has ended"
                    presenterDeskshareHasEnded()

# Detects a mobile device
@isMobile = ->
  navigator.userAgent.match(/Android/i) or
  navigator.userAgent.match(/iPhone|iPad|iPod/i) or
  navigator.userAgent.match(/BlackBerry/i) or
  navigator.userAgent.match(/Windows Phone/i) or
  navigator.userAgent.match(/IEMobile/i) or
  navigator.userAgent.match(/BlackBerry/i) or
  navigator.userAgent.match(/webOS/i)

@isLandscape = ->
  not isMobile() and
  window.matchMedia('(orientation: landscape)').matches and      # browser is landscape
  window.matchMedia('(min-device-aspect-ratio: 1/1)').matches    # device is landscape

@isPortrait = ->
  not isMobile() and
  window.matchMedia('(orientation: portrait)').matches and       # browser is portrait
  window.matchMedia('(min-device-aspect-ratio: 1/1)').matches    # device is landscape

# Checks if the view is portrait and a mobile device is being used
@isPortraitMobile = () ->
 isMobile() and
 window.matchMedia('(orientation: portrait)').matches and        # browser is portrait
 window.matchMedia('(max-device-aspect-ratio: 1/1)').matches     # device is portrait

# Checks if the view is landscape and mobile device is being used
@isLandscapeMobile = () ->
  isMobile() and
  window.matchMedia('(orientation: landscape)').matches and      # browser is landscape
  window.matchMedia('(min-device-aspect-ratio: 1/1)').matches    # device is landscape

@isLandscapePhone = () ->
  # @phone-landscape media query:
  window.matchMedia('(orientation: landscape)').matches and
  window.matchMedia('(min-device-aspect-ratio: 1/1)').matches and
  window.matchMedia('(max-device-width: 959px)').matches

@isPortraitPhone = () ->
  # @phone-portrait media query:
  (window.matchMedia('(orientation: portrait)').matches and
  window.matchMedia('(max-device-aspect-ratio: 1/1)').matches and
  window.matchMedia('(max-device-width: 480px)').matches) or
  # @phone-portrait-with-keyboard media query:
  (window.matchMedia('(orientation: landscape)').matches and
  window.matchMedia('(max-device-aspect-ratio: 1/1)').matches and
  window.matchMedia('(max-device-width: 480px)').matches)

@isPhone = () ->
  isLandscapePhone() or isPortraitPhone()

# Checks if only one panel (userlist/whiteboard/chatbar) is currently open
@isOnlyOnePanelOpen = () ->
  #(getInSession "display_usersList" ? 1 : 0) + (getInSession "display_whiteboard" ? 1 : 0) + (getInSession "display_chatbar" ? 1 : 0) is 1
  getInSession("display_usersList") + getInSession("display_whiteboard") + getInSession("display_chatbar") is 1

# determines which browser is being used
@getBrowserName = () ->
  if navigator.userAgent.match(/Chrome/i)
    return 'Chrome'
  else if navigator.userAgent.match(/Firefox/i)
    return 'Firefox'
  else if navigator.userAgent.match(/Safari/i)
    return 'Safari'
  else if navigator.userAgent.match(/Trident/i)
    return 'IE'
  else
    return null

# changes the height of the chat input area if needed (based on the textarea content)
@adjustChatInputHeight = () ->
  $('#newMessageInput').css('height', 'auto')
  projectedHeight = $('#newMessageInput')[0].scrollHeight + 23
  if projectedHeight isnt $('.panel-footer').height() and
  projectedHeight >= getInSession('chatInputMinHeight')
    $('#newMessageInput').css('overflow', 'hidden') # prevents a scroll bar

    # resizes the chat input area
    $('.panel-footer').css('top', - (projectedHeight - 70) + 'px')
    $('.panel-footer').css('height', projectedHeight + 'px')

    $('#newMessageInput').height($('#newMessageInput')[0].scrollHeight)

    # resizes the chat messages container
    $('#chatbody').height($('#chat').height() - projectedHeight - 45)
    $('#chatbody').scrollTop($('#chatbody')[0]?.scrollHeight)
  $('#newMessageInput').css('height', '')
