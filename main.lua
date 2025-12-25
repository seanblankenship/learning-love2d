local player = {}
local window = {}

function love.load()
  love.window.setTitle("Learning love2d")

  window.w, window.h = love.graphics.getDimensions()

  player.w = 80
  player.h = 80
  player.speed = 250

  --start centered
  player.x = (window.w - player.w) / 2
  player.y = (window.h - player.h) / 2

  player.isMoving = false
  player.touchingEdge = false

  player.maxHealth = 100
  player.health = player.maxHealth
  player.regenTimer = 0
end

function love.update(dt)
  --refresh window dimensions if the window is resized
  window.w, window.h = love.graphics.getDimensions()

  local dx, dy = 0, 0

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

  player.isMoving = (dx ~= 0 or dy ~= 0)

  --if you move diagonally, normalize for consistent speed
  if dx ~= 0 and dy ~= 0 then
    local inv = 1 / math.sqrt(2)
    dx = dx * inv
    dy = dy * inv
  end

  local newX = player.x + dx * player.speed * dt
  local newY = player.y + dy * player.speed * dt

  player.touchingEdge = false

  --clamp and detect edge contact
  if newX < 0 then
    newX = 0
    player.touchingEdge = true
  elseif newX + player.w > window.w then
    newX = window.w - player.w
    player.touchingEdge = true
  end

  if newY < 0 then
    newY = 0
    player.touchingEdge = true
  elseif newY + player.h > window.h then
    newY = window.h - player.h
    player.touchingEdge = true
  end

  player.x = newX
  player.y = newY

  --damage when pushing into an edge
  if player.touchingEdge and player.isMoving and player.health > 0 then
    player.health = player.health - 1
  end

  --player health regen: +1 hp every 2s while below max
  if player.health < player.maxHealth then
    player.regenTimer = player.regenTimer + dt
    if player.regenTimer >= 2 then
      player.health = player.health + 1
      if player.health > player.maxHealth then
        player.health = player.maxHealth
      end
      player.regenTimer = player.regenTimer -2
    end
  else
    --at full health, no need to count
    player.regenTimer = 0
  end

end

function love.draw()
  --the player
  if player.touchingEdge then
    love.graphics.setColor(1, 0, 0)
  elseif player.isMoving then
    love.graphics.setColor(0, 1, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  --health bar
  local barWidth, barHeight = 200, 20
  local margin = 10
  local x = window.w - barWidth - margin
  local y = margin

  local ratio = player.health / player.maxHealth

  --bar bg
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", x - 2, y - 2, barWidth + 4, barHeight + 4)

  --bar fill
  love.graphics.setColor(0.8, 0, 0)
  love.graphics.rectangle("fill", x, y, barWidth * ratio, barHeight)

  --health text
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(string.format("HP: %d / %d", player.health, player.maxHealth), x, y + barHeight + 4)

  --instructions and debug info
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("controls: k j h l to move", 10, 10)
  love.graphics.print("touching edge: red | moving: green | idle: white", 10, 30)
  love.graphics.print(string.format("player: x=%.1f, y=%.1f", player.x, player.y), 10, 50)
end
