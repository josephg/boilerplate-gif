#!/usr/bin/env node

Simulator = require 'boilerplate-sim'
GifEncoder = require("gifencoder")
fs = require 'fs'

Canvas = require 'canvas'

parseXY = (k) ->
  [x,y] = k.split /,/
  {x:parseInt(x), y:parseInt(y)}

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

  s = new Simulator grid

  extents = s.boundingBox()

  # Tile width / height
  tw = extents.right - extents.left + 2
  th = extents.bottom - extents.top + 2

  size = opts.size || (opts.width / tw) || (opts.height / th) || Math.max(20, 300/tw)
  size = size|0
  # Pixel width / height
  pw = tw * size
  ph = th * size

  worldToScreen = (tx, ty) -> {px:(tx-extents.left+1) * size, py:(ty-extents.top+1) * size}

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

    s.drawCanvas ctx, size, worldToScreen
    encoder.addFrame ctx


    s.step()

  encoder.finish()

  outputFilename

