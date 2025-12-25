--find the window width and height
local ww, wh = love.graphics.getDimensions()

--set the player size and movement speed
player = { 
  w = 50, 
  h = 50, 
  speed = 200 
}

--set the initial player position in the middle of the screen
player.x = (ww - player.w) / 2
player.y = (wh - player.h) / 2

--vim controls
function love.update(dt)
  if love.keyboard.isDown("k") then player.y = player.y - player.speed * dt end --up
  if love.keyboard.isDown("j") then player.y = player.y + player.speed * dt end --down
  if love.keyboard.isDown("l") then player.x = player.x + player.speed * dt end --right
  if love.keyboard.isDown("h") then player.x = player.x - player.speed * dt end --left
end

--draw the player in the window
function love.draw()
  love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
end
