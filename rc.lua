-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Audio control widget.
local APW = require("apw/widget")
-- Load Debian menu entries
require("debian.menu")

-- Delightful widgets
require('delightful.widgets.battery')
require('delightful.widgets.cpu')
require('delightful.widgets.datetime')
-- require('delightful.widgets.imap')
require('delightful.widgets.memory')
require('delightful.widgets.network')
require('delightful.widgets.pulseaudio')
-- require('delightful.widgets.weather')

-- Which widgets to install?
-- This is the order the widgets appear in the wibox.
delightful_widgets = {
    delightful.widgets.network,
    delightful.widgets.cpu,
    delightful.widgets.memory,
    -- delightful.widgets.weather,
    -- delightful.widgets.imap,
    delightful.widgets.battery,
    delightful.widgets.pulseaudio,
    delightful.widgets.datetime,
}

-- Widget configuration
delightful_config = {
    [delightful.widgets.cpu] = {
        command = 'gnome-system-monitor',
    },
    [delightful.widgets.memory] = {
        command = 'gnome-system-monitor',
    },
--    [delightful.widgets.weather] = {
--        {
--            city = 'Brussels',
--            command = 'gnome-www-browser http://ilmatieteenlaitos.fi/saa/Brussels',
--        },
--    },
    [delightful.widgets.network] = {
        excluded_devices = { 'virbr0', 'docker0' },
    },
    [delightful.widgets.pulseaudio] = {
        mixer_command = 'pavucontrol',
    },
}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
home = os.getenv("HOME")
-- Themes define colours, icons, font and wallpapers.
wallpapers = home .. "/wallpapers/"
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor
browser = "firefox"
explorer = "nautilus --no-desktop"
lockscreen = function() awful.util.spawn("slock") end
xrandr_switch_cmd = "sudo ~/.config/awesome/xrandr_switch.sh ~/.config/awesome/xrandr.configs "

-- {{{ Spawning processes
local function is_running(cmd)
    -- we escape all '+' characters with '\'
    local escaped_cmd = string.gsub(cmd, "+", "\\+")
    -- otherwise pgrep will not find the process
    local running = (os.execute("pgrep -fu $USER '" .. escaped_cmd .. "'") == 0)
    return running
end

-- Spawn process, if it is not already running
local function run_once(cmd)
    if not is_running(cmd) then
        naughty.notify({ title = "Starting: ", text = cmd, timeout = 3 })
        awful.util.spawn_with_shell(cmd)
    else
        naughty.notify({ title = "Already running: ", text = cmd, timeout = 3 })
    end
end

-- Function to spawn an application in a specific screen/tag
function spawn_to(command, class, tag, test, once)
local test = test or "class"
local callback
callback = function(c)
    if test == "class" then
        if c.class == class then
            awful.client.movetotag(tag, c)
            client.disconnect_signal("manage", callback)
        end
    elseif test == "instance" then
        if c.instance == class then
            awful.client.movetotag(tag, c)
            client.disconnect_signal("manage", callback)
        end
    elseif test == "name" then
        if string.match(c.name, class) then
            awful.client.movetotag(tag, c)
            client.disconnect_signal("manage", callback)
        end
    end
end
client.connect_signal("manage", callback)
if once then
    run_once(command)
else
    awful.util.spawn_with_shell(command)
end
end
-- }}}


-- {{{ Confirmation Popup

function confirm_action(func, name)
   mywibox[mouse.screen]:set_bg(beautiful.bg_urgent)
   mywibox[mouse.screen]:set_fg(beautiful.fg_urgent)
   awful.prompt.run({prompt = name .. " [y/N] "},
      mypromptbox_conf[mouse.screen].widget,
      function (t)
         if string.lower(t) == 'y' then
            func()
         end
      end,
      nil, nil, 0,
      function ()
         mywibox[mouse.screen]:set_bg(beautiful.screen_highlight_bg_active)
         mywibox[mouse.screen]:set_fg(beautiful.screen_highlight_fg_active)
      end
   )
end
-- }}}

-- {{{ Random Wallpapers
-- Get the list of files from a directory. Must be all images or folders and non-empty
function scanDir(directory)
    local i, fileList, popen = 0, {}, io.popen
    for filename in popen([[find "]] ..directory.. [[" -type f]]):lines() do
        i = i + 1
        fileList[i] = filename
    end
    return fileList
end
wallpaperList = scanDir(wallpapers)

-- Prevent wallpaper from Nautilus or other gnome stuff (Adrien!?)
awful.util.spawn_with_shell("gsettings set org.gnome.desktop.background draw-background false")

-- Apply a random wallpaper on startup
for s = 1, screen.count() do
    gears.wallpaper.maximized(wallpaperList[math.random(1, #wallpaperList)], s, false)
end

-- Apply a random wallpaper every changeTime seconds
changeTime = 120
wallpaperTimer = timer { timeout = changeTime }
wallpaperTimer:connect_signal("timeout", function()
    for s = 1, screen.count() do
        gears.wallpaper.maximized(wallpaperList[math.random(1, #wallpaperList)], s, false)
    end
    -- stop the timer (we don't need multiple instances running at the same time)
    wallpaperTimer:stop()
    -- restart the timer
    wallpaperTimer.timeout = changeTime
    wallpaperTimer:start()
end)

-- initial start when rc.lua is first run
wallpaperTimer:start()
-- }}}


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}


-- {{ Shutdown menu

-- Session management icons
local icon_shutdown = "/usr/share/icons/Humanity/actions/16/system-shutdown.svg"
local icon_restart = "/usr/share/icons/Humanity/actions/16/system-restart-panel.svg"
local icon_logout = "/usr/share/icons/Humanity/actions/16/system-log-out.svg"
local icon_lock = "/usr/share/icons/Humanity/actions/16/system-lock-screen.svg"

-- System menu
system_menuitems = {
   { "Shutdown",
     function() confirm_action(
           function()
              awful.util.spawn('sudo /sbin/shutdown -h now')
           end, "Shutdown")
     end, icon_shutdown },
   { "Restart",
     function() confirm_action(
           function()
              awful.util.spawn('sudo /sbin/shutdown -r now')
           end, "Reboot")
     end, icon_restart },
   { "Logout",
     function() confirm_action(
           function()
              awesome.quit()
           end, "Logout")
     end, icon_logout },
   { "Lock",
     function()
           lockscreen()
     end, icon_lock }
}
system_launcher = awful.widget.launcher({
--      image = icon_shutdown,
      menu = awful.menu({ items = system_menuitems}) })
-- }}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "Lock", lockscreen, icon_lock },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal },
                                    { "System", system_menuitems }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Keyboard layout management
-- NOT USED
kbdcfg = {}
kbdcfg.cmd = "setxkbmap"
kbdcfg.layout = { { "us", "" }, { "be", "" } }
kbdcfg.current = 1  -- de is our default layout
kbdcfg.widget = wibox.widget.textbox()
kbdcfg.widget:set_text(" " .. kbdcfg.layout[kbdcfg.current][1] .. " ")
kbdcfg.switch = function ()
  kbdcfg.current = kbdcfg.current % #(kbdcfg.layout) + 1
  local t = kbdcfg.layout[kbdcfg.current]
  kbdcfg.widget:set_text(" " .. t[1] .. " ")
  os.execute( kbdcfg.cmd .. " " .. t[1] .. " " .. t[2] )
end

 -- Mouse bindings
kbdcfg.widget:buttons(
 awful.util.table.join(awful.button({ }, 1, function () kbdcfg.switch() end))
)
-- }}}

-- {{{ Wibox

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mywibox_prompt = {}
mypromptbox_conf = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Create a confirmation promptbox for each screen
    mypromptbox_conf[s] = awful.widget.prompt()
    mywibox_prompt[s] = awful.wibox({ position = "bottom", screen = s,
                                          font = "Consolas 18" })
    mywibox_prompt[s].visible = false
    mywibox_prompt[s]:set_widget(mypromptbox[s])
    left_layout:add(mypromptbox_conf[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then
        right_layout:add(wibox.widget.systray())
        delightful.utils.fill_wibox_container(delightful_widgets, delightful_config, right_layout)
    end
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the miRddle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "b", function () awful.util.spawn(browser) end),
    awful.key({ modkey,           }, "e", function () awful.util.spawn(explorer) end),
    awful.key({ modkey,           }, "a", function () awful.util.spawn("atom") end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    -- awful.key({ modkey, "Shift"   }, "q", awesome.quit),
    awful.key({ modkey, "Shift"   }, "q", function() confirm_action(
               function()
                  awesome.quit()
               end, "Logout")
         end),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    awful.key({ modkey,           }, "Escape", lockscreen),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- Multiple monitors
    awful.key({ modkey,           }, "F1",     function () awful.screen.focus(1) end),
    awful.key({ modkey, "Shift"   }, "F1",     function(c) awful.client.movetoscreen(c,1) end ),
    awful.key({ modkey,           }, "F2",     function () awful.screen.focus(2) end),
    awful.key({ modkey, "Shift"   }, "F2",     function(c) awful.client.movetoscreen(c,2) end ),
    awful.key({ modkey,           }, "F3",     function () awful.screen.focus(3) end),
    awful.key({ modkey, "Shift"   }, "F3",     function(c) awful.client.movetoscreen(c,3) end ),

    -- Volume Control
    awful.key({}, "XF86AudioMute", APW.ToggleMute),
    awful.key({}, "XF86AudioLowerVolume", APW.Down),
    awful.key({}, "XF86AudioRaiseVolume", APW.Up),

    -- Logout
    awful.key({ modkey, "Shift"   }, "q", function () awful.util.spawn("/usr/bin/gnome-session-quit  --logout --no-prompt") end),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),

    -- xrandr
    -- awful.key({ modkey }, "XF86Display", xrandr)
    -- awful.key({ modkey }, "F8", xrandr)
    awful.key({ modkey }, "F8", function () awful.util.spawn_with_shell(xrandr_switch_cmd .. " 2") end),
    awful.key({ modkey, "Shift" }, "F8", function () awful.util.spawn_with_shell(xrandr_switch_cmd .. " 1") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys

globalkeys = awful.util.table.join(globalkeys, xrandrkeys)

root.keys(globalkeys)
-- }}}

naughty.notify({ title = "Screens: ", text = "n=" .. screen.count(), timeout = 3 })

-- {{{
-- for i = 1, #wallpaperList do
--  naughty.notify({ title = "Wallpapers: ", text = "wp[1]=" .. wallpaperList[i], timeout = 30 })
-- end
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
screen2 = 2
screen3 = 3
if (screen.count() < 2) then
    screen2 = 1
end
if (screen.count() < 3) then
    screen3 = screen2
end
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set apps to always map on specific tags and screens.
    { rule = { class = "Firefox" },
       properties = { tag = tags[1][1] } },
    { rule = { class = "Eclipse" },
       properties = { tag = tags[screen2][1] } },
    -- { rule = { class = "Wireshark" },
    --   properties = { tag = tags[screen2][4] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    elseif not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count change
        awful.placement.no_offscreen(c)
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- }}}

-- {{{ Disable touchpad edge scrolling
awful.util.spawn_with_shell("synclient VertEdgeScroll=0")
-- }}}

run_once("nm-applet")
awful.util.spawn_with_shell('~/.config/awesome/locker.sh')

-- Launch startup apps

run_once("skypeforlinux")

run_once("blueman-applet")

-- run_once("thunderbird")

if (not is_running(browser)) then
    spawn_to(browser .. " https://chat.tessares.net/channel/dev-discuss https://mail.google.com https://calendar.google.com/calendar https://jira.tessares.net/secure/RapidBoard.jspa?rapidView=47", "Firefox", tags[1][1], "class", true)
end
