local player = {}
local window = {}

function love.load()
  love.window.setTitle("Learning love2d")

  window.w, window.h = love.graphics.getDimensions()

  player.animations = {
    idle = {
      image = love.graphics.newImage("/assets/player/idle.png"),
      frameWidth = 60,
      frameHeight = 60,
      frameCount = 4,
      frameDuration = 0.15,
      frames = {}
    },
    run = {
      image = love.graphics.newImage("/assets/player/run.png"),
      frameWidth = 60,
      frameHeight = 60,
      frameCount = 8,
      frameDuration = 0.10,
      frames = {}
    },
    death = {
      image = love.graphics.newImage("/assets/player/death.png"),
      frameWidth = 60,
      frameHeight = 60,
      frameCount = 8,
      frameDuration = 0.12,
      frames = {}
    }
  }

  -- build quads for each animation
  for name, anim in pairs(player.animations) do
    for i = 0, anim.frameCount - 1 do
      anim.frames[i + 1] = love.graphics.newQuad(
        i * anim.frameWidth, 0,
        anim.frameWidth, anim.frameHeight,
        anim.image:getWidth(),
        anim.image:getHeight()
      )
    end
  end

  player.state = "idle"
  player.currentFrame = 1
  player.frameTime = 0

  player.w = 60
  player.h = 60
  player.speed = 250

  -- start centered
  player.x = (window.w - player.w) / 2
  player.y = (window.h - player.h) / 2

  player.isMoving = false
  player.touchingEdge = false

  player.maxHealth = 100
  player.health = player.maxHealth
  player.regenTimer = 0

  player.facing = 1 -- 1 = right, -1 = left
end

function love.update(dt)
  -- refresh window dimensions if the window is resized
  window.w, window.h = love.graphics.getDimensions()

  local dx, dy = 0, 0

  if player.state ~= "death" then
    if love.keyboard.isDown("up") or love.keyboard.isDown("k") then
      dy = dy - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("j") then
      dy = dy + 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("l") then
      dx = dx + 1
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("h") then
      dx = dx - 1
    end
  end

  player.isMoving = (dx ~= 0 or dy ~= 0)

  -- direction player is facing
  if dx > 0 then
    player.facing = 1
  elseif dx < 0 then
    player.facing = -1
  end

  -- if you move diagonally, normalize for consistent speed
  if dx ~= 0 and dy ~= 0 then
    local inv = 1 / math.sqrt(2)
    dx = dx * inv
    dy = dy * inv
  end

  local newX = player.x + dx * player.speed * dt
  local newY = player.y + dy * player.speed * dt

  player.touchingEdge = false

  -- clamp and detect edge contact (x)
  if newX < 0 then
    newX = 0
    player.touchingEdge = true
  elseif newX + player.w > window.w then
    newX = window.w - player.w
    player.touchingEdge = true
  end

  -- clamp and detect edge contact (y)
  if newY < 0 then
    newY = 0
    player.touchingEdge = true
  elseif newY + player.h > window.h then
    newY = window.h - player.h
    player.touchingEdge = true
  end

  player.x = newX
  player.y = newY

  -- damage when pushing into an edge (only if alive)
  if player.state ~= "death" and player.touchingEdge and player.isMoving and player.health > 0 then
    player.health = player.health - 1
  end

  -- clamp health at zero and enter death state
  if player.health <= 0 and player.state ~= "death" then
    player.health = 0
    player.state = "death"
    player.currentFrame = 1
    player.frameTime = 0
  end

  -- health regen: +1 hp every 2s while below max and not dead
  if player.state ~= "death" and player.health < player.maxHealth then
    player.regenTimer = player.regenTimer + dt
    if player.regenTimer >= 2 then
      player.health = player.health + 1
      if player.health > player.maxHealth then
        player.health = player.maxHealth
      end
      player.regenTimer = player.regenTimer - 2
    end
  elseif player.health >= player.maxHealth then
    player.regenTimer = 0
  end

  -- decide desired state (if not dead)
  local newState = player.state
  if player.state ~= "death" then
    if player.isMoving then
      newState = "run"
    else
      newState = "idle"
    end
  end

  -- if state changed, reset animation
  if newState ~= player.state then
    player.state = newState
    player.currentFrame = 1
    player.frameTime = 0
  end

  local anim = player.animations[player.state]

  if player.state == "death" then
    -- play once, stop on last frame
    if player.currentFrame < anim.frameCount then
      player.frameTime = player.frameTime + dt
      if player.frameTime >= anim.frameDuration then
        player.frameTime = player.frameTime - anim.frameDuration
        player.currentFrame = player.currentFrame + 1
        if player.currentFrame > anim.frameCount then
          player.currentFrame = anim.frameCount -- clamp to last frame
        end
      end
    end
  else
    -- loop animation (idle/run)
    player.frameTime = player.frameTime + dt
    if player.frameTime >= anim.frameDuration then
      player.frameTime = player.frameTime - anim.frameDuration
      player.currentFrame = player.currentFrame + 1
      if player.currentFrame > anim.frameCount then
        player.currentFrame = 1
      end
    end
  end
end

function love.draw()
  -- color by state/edge
  if player.touchingEdge then
    love.graphics.setColor(1, 0, 0)
  elseif player.isMoving then
    love.graphics.setColor(0, 1, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end

  local anim = player.animations[player.state]

  -- safety clamp for currentFrame
  if player.currentFrame < 1 then
    player.currentFrame = 1
  elseif player.currentFrame > anim.frameCount then
    player.currentFrame = anim.frameCount
  end

  local quad = anim.frames[player.currentFrame]

  -- flipping
  local sx = player.facing  -- 1 or -1
  local ox = 0

  if player.facing == -1 then
    -- flip around vertical axis at left edge
    sx = -1
    ox = player.w -- shift origin so x stays at left
  end

  love.graphics.draw(
    anim.image,
    quad,
    player.x,
    player.y,
    0,    -- rotation
    sx,   -- scale X
    1,    -- scale Y
    ox,   -- origin X
    0     -- origin Y
  )

  -- reset color for UI
  love.graphics.setColor(1, 1, 1)

  -- health bar
  local barWidth, barHeight = 200, 20
  local margin = 10
  local x = window.w - barWidth - margin
  local y = margin

  local ratio = player.health / player.maxHealth

  -- bar bg
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", x - 2, y - 2, barWidth + 4, barHeight + 4)

  -- bar fill
  love.graphics.setColor(0.8, 0, 0)
  love.graphics.rectangle("fill", x, y, barWidth * ratio, barHeight)

  -- health text
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(string.format("HP: %d / %d", player.health, player.maxHealth), x, y + barHeight + 4)

  -- instructions and debug info
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("controls: k j h l to move", 10, 10)
  love.graphics.print("touching edge: red | moving: green | idle: white", 10, 30)
  love.graphics.print(string.format("player: x=%.1f, y=%.1f", player.x, player.y), 10, 50)
end