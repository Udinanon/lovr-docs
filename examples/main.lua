function lovr.load()
  local width, height = 360, 400

  local backbuffer = lovr.graphics.newTexture(width, height, {
    usage = { 'render', 'transfer' },
    mipmaps = false
  })

  local readback

  for i, category in ipairs(lovr.filesystem.getDirectoryItems('/')) do
    if lovr.filesystem.isDirectory(category) and not category:match('^%.') then
      for j, project in ipairs(lovr.filesystem.getDirectoryItems(category)) do
        local path = table.concat({ category, project }, '/')
        local file = path .. '/main.lua'

        local ok, chunk = pcall(lovr.filesystem.load, file)

        if not ok then
          print(string.format('Could not parse %q (%s)', file, chunk))
        else
          local env

          env = setmetatable({
            lovr = setmetatable({
              headset = setmetatable({
                getDriver = function()
                  return 'openxr'
                end,
                getName = function()
                  return 'Extremely Spooky Headset You Have Never Heard Of!!'
                end,
                getOriginType = function()
                  return 'floor'
                end,
                getDisplayWidth = function()
                  return width
                end,
                getDisplayHeight = function()
                  return height
                end,
                getDisplayDimensions = function()
                  return width, height
                end,
                getViewCount = function()
                  return 1
                end,
                getViewPose = function()
                  return 0, 1.7, 0, 0, 0, 0, 0
                end,
                getViewAngles = function()
                  return 1, 1, 1, 1
                end,
                isTracked = function(device)
                  return device == 'head' or
                    device:gsub('^hand/', '') == 'left' or
                    device:gsub('^hand/', '') == 'right'
                end,
                getPose = function(device)
                  if device == 'head' then
                    return 0, 1.7, 0, 0, 0, 0, 0
                  end

                  return 0, 0, 0, 0, 0, 0, 0
                end,
                getPosition = function(device)
                  return 0, 1.7, 0
                end,
                getOrientation = function(device)
                  return 0, 0, 0, 0
                end,
                getVelocity = function(device)
                  return 0, 0, 0
                end,
                getAngularVelocity = function(device)
                  return 0, 0, 0
                end,
                isDown = function(device, button)
                  return false
                end,
                wasPressed = function(device, button)
                  return false
                end,
                wasReleased = function(device, button)
                  return false
                end,
                isTouched = function(device, button)
                  return false
                end,
                getAxis = function(device, axis)
                  return 0, 0
                end,
                getSkeleton = function(device)
                  return nil
                end,
                update = function()
                  return 0
                end,
                getTime = function()
                  return 0
                end,
                getDeltaTime = function()
                  return 0
                end,
                getPass = function()
                  local pass = lovr.graphics.getPass('render', {
                    [1] = backbuffer,
                    depth = 'd32fs8',
                    clear = { lovr.graphics.getBackgroundColor() }
                  })

                  for i = 1, env.lovr.headset.getViewCount() do
                    pass:setViewPose(i, env.lovr.headset.getViewPose(i))
                    pass:setProjection(i, env.lovr.headset.getViewAngles(i))
                  end

                  return pass
                end,
                submit = function()
                  local tx = lovr.graphics.getPass('transfer')
                  readback = tx:read(backbuffer)
                  lovr.graphics.submit(tx)
                end,
                getHands = function()
                  return { 'hand/left', 'hand/right' }
                end
              }, { __index = lovr.headset }),
              load = function() end,
              update = function() end,
              draw = function() end,
            }, { __index = lovr })
          }, { __index = _G })

          setfenv(chunk, env)

          lovr.graphics.setBackgroundColor(0, 0, 0, 1)
          lovr.filesystem.mount(path, '/', false)

          local ok, result = pcall(chunk)

          if ok and env.lovr.run then
            local ok, thread = pcall(setfenv(env.lovr.run, env))

            if not ok or not thread then
              print('i literally cant even run lovr.run', project)
            else
              readback = nil

              thread()

              if readback then
                readback:wait()
                local image = readback:getImage()
                lovr.filesystem.write(project .. '.png', image:encode())
              end
            end
          else
            print(string.format('ok i literally cant %s', project))
          end

          lovr.filesystem.unmount(path)
        end
      end
    end
  end

  lovr.event.quit()
end
