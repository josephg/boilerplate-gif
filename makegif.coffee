#!/usr/bin/env node

Simulator = require 'boilerplate-sim'
GifEncoder = require("gifencoder")
fs = require 'fs'

Canvas = require 'canvas'

colors =
  bridge: '#2E96D6'
  negative: '#D65729'
  nothing: '#FFFFFF'
  positive: '#5CCC5C'
  shuttle: '#9328BD'
  solid: '#09191B'
  thinshuttle: '#D887F8'
  thinsolid: '#B5B5B5'

darkColors =
  bridge: '#487693'
  negative: '#814B37'
  nothing: '#7D7D7D'
  positive: '#4D8F4D'
  shuttle: '#604068'
  solid: '#706F76'
  thinshuttle: '#8E56A4'
  thinsolid: '#7D7D7D'

parseXY = (k) ->
  [x,y] = k.split /,/
  {x:parseInt(x), y:parseInt(y)}

gridExtents = (grid) ->
  # calculate the extents
  top = left = bottom = right = null

  for k, v of grid
    {x,y} = parseXY k
    left = x if left is null || x < left
    right = x if right is null || x > right
    top = y if top is null || y < top
    bottom = y if bottom is null || y > bottom

  {top, left, bottom, right}

draw = (simulator, ctx, worldToScreen, size) ->
  # Draw the tiles
  pressure = simulator.getPressure()
  for k,v of simulator.grid
    {x:tx,y:ty} = parseXY k
    {px, py} = worldToScreen tx, ty

    ctx.fillStyle = colors[v]
    ctx.fillRect px, py, size, size

    if v is 'nothing' and (v2 = simulator.get(tx,ty-1)) isnt 'nothing'
      ctx.fillStyle = darkColors[v2 ? 'solid']
      ctx.fillRect px, py, size, size*0.3

    if (p = pressure[k]) and p != 0
      ctx.fillStyle = if p < 0 then 'rgba(255,0,0,0.2)' else 'rgba(0,255,0,0.15)'
      ctx.fillRect px, py, size, size

  zeroPos = worldToScreen 0, 0
  ctx.lineWidth = 3
  ctx.strokeStyle = 'yellow'

isEmpty = (obj) ->
  for k of obj
    return false
  return true

module.exports = makeGif = (inputFilename, outputFilename, opts = {}) ->
  opts.delay ||= 200
  opts.repeat ?= true

  if !outputFilename
    path = require 'path'
    outputFilename = (path.basename(inputFilename).split('.')[0]) + '.gif'

  grid = JSON.parse fs.readFileSync(inputFilename, 'utf8').split('\n')[0]
  delete grid.tw
  delete grid.th

  #console.log grid

  extents = gridExtents grid

  # Tile width / height
  tw = extents.right - extents.left + 3
  th = extents.bottom - extents.top + 3

  size = opts.size || (opts.width / tw) || (opts.height / th) || Math.max(20, 300/tw)
  size = size|0
  # Pixel width / height
  pw = tw * size
  ph = th * size

  worldToScreen = (tx, ty) -> {px:(tx-extents.left+1) * size, py:(ty-extents.top+1) * size}

  s = new Simulator grid

  canvas = new Canvas pw, ph
  encoder = new GifEncoder pw, ph
  encoder.createReadStream().pipe fs.createWriteStream(outputFilename)
  encoder.start()
  encoder.setRepeat (if opts.repeat then 0 else -1)
  encoder.setDelay opts.delay

  ctx = canvas.getContext '2d'

  # Simulate 100 steps, or until the simulator loops or stops changing.
  seenState = {}
  for [1..30]
    key = JSON.stringify s.getGrid()

    #console.log key

    break if seenState[key]
    seenState[key] = true

    draw s, ctx, worldToScreen, size
    encoder.addFrame ctx


    s.step()

  encoder.finish()

  outputFilename

