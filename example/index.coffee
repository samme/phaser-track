"use strict"

{dat, Phaser} = this
{CENTER} = Phaser
{ADD} = Phaser.blendModes
{Cubic} = Phaser.Easing

GREEN = "rgba(0,255,0,0.5)"
VIOLET = "rgba(255,0,255,0.5)"
SECOND = 1000

_line = new Phaser.Line

Phaser.Pointer::toString = ->
  "[Pointer ID #{@id}]"

Phaser.Sprite::toString = ->
  "[Sprite: #{@name or ("["+@key+"]")}]"

createGui = (ship, sprite, flames) ->
  gui = new dat.GUI
  folders = {}

  for obj in [ship, sprite, flames]
    {name} = obj
    folder = folders[name] = gui.addFolder name

    if obj.on?
      folder.add obj, "on"

    folder.add(obj, method) for method in ["destroy", "kill", "revive"]
    folder.add obj, "reset" if obj.reset

    if obj.data.trackTarget
      folder.add obj, "untrack"

    {trackOffset} = obj.data
    if trackOffset
      offsetFolder = folder.addFolder "trackOffset"
      offsetFolder.add trackOffset, "x", -250, 250, 5
      offsetFolder.add trackOffset, "y", -250, 250, 5
      offsetFolder.open()

    folder.open()

  folders.state = gui.addFolder "game.state"
  folders.state.add ship.game.state, "restart"
  folders.state.open()

  gui

window.GAME = new (Phaser.Game)
  # antialias: no
  # height: 600
  renderer: Phaser.CANVAS
  # resolution: 1
  # scaleMode: Phaser.ScaleManager.NO_SCALE
  # transparent: false
  # width: 800
  state:

    init: ->
      {debug} = @game
      debug.font = "16px Consolas, Menlo, monospace"
      debug.lineHeight = 25
      return

    preload: ->
      @load.baseURL = "https://cdn.jsdelivr.net/gh/samme/phaser-examples-assets@v2.0.0/assets/"
      @load.crossOrigin = "anonymous"
      @load.image "dude", "sprites/phaser-dude.png"
      @load.image "ship", "sprites/ship.png"
      @load.image "star", "demoscene/star.png"
      @load.image "star2", "demoscene/star2.png"
      return

    create: ->
      @physics.arcade.gravity.y = 60

      ship = @ship = @add.sprite 0, 0, "ship"
      ship.name = "ship"
      ship.anchor.set 0.5
      ship.alignIn @world.bounds, CENTER
      ship.inputEnabled = on
      ship.input.enableDrag()
      ship.input.useHandCursor = on
      @physics.enable ship
      ship.body.allowGravity = no
      ship.body.angularVelocity = 30

      sprite = @sprite = @add.sprite 0, 0, "dude"
      sprite.name = "dude"
      sprite.anchor.set 0.5
      @physics.enable sprite
      sprite.body.angularVelocity = 60
      sprite.track ship,
        offsetX: 0
        offsetY: -80
        trackRotation: yes
        rotateOffset: yes

      flames = @flames = @add.emitter 0, 0, 20
        .setAlpha 0.75, 0, 4 * SECOND, Cubic.Out
        .setRotation -360, 360
        .setScale 4, 1, 4, 1, 4 * SECOND, Cubic.Out
        .setXSpeed -25, 25
        .setYSpeed -25, 75
        .makeParticles "star"
        .flow 2 * SECOND, 100
      flames.name = "flames"
      flames.blendMode = ADD
      flames.gravity = -60
      flames.track ship,
        offsetX: 0
        offsetY: 35
        trackRotation: no
        rotateOffset: yes

      stars = @stars = @add.emitter 0, 0, 10
        .setAlpha 1, 0, 2 * SECOND
        .makeParticles "star2"
        .flow SECOND, 100
      stars.name = "stars"
      stars.blendMode = ADD
      stars.gravity = -30
      stars.track @input.activePointer

      @add.text 20, 560, "Drag the ship around (↑) or kill/revive/destroy it (→)",
        fill: "#E800B0"
        font: "bold #{@game.debug.font}"

      @gui = createGui ship, sprite, flames

      return

    render: ->
      {debug} = @game

      x = 20
      y = 30
      dx = 320
      dy = 145

      @debugTracking @sprite, x, y
      # @debugTrackingData @sprite, x, y

      if @sprite.body # unless destroyed
        debug.object @sprite.body, x + dx, y,
          color: "auto"
          keys: ["moves"]
          label: "dude.body"
          sort: yes

      if @sprite.trackTarget
        @debugLine @sprite.trackTarget.x, @sprite.trackTarget.y, @sprite.x, @sprite.y, GREEN

      @debugTracking @flames, x, y += dy
      # @debugTrackingData @flames, x, y += dy

      if @flames.trackTarget
        @debugLine @flames.trackTarget.x, @flames.trackTarget.y, @flames.emitX, @flames.emitY, VIOLET

      @debugTracking @stars, x, y += dy
      # @debugTrackingData @stars, x, y += dy

      debug.object @ship, x, y += dy,
        color: "auto"
        keys: ["exists"]
        label: "ship"

      return

    shutdown: ->
      @gui.destroy()
      return

    debugLine: (startX, startY, endX, endY, color) ->
      _line.setTo startX, startY, endX, endY
      @game.debug.geom _line, color if _line.length > 0
      return

    debugTracking: (obj, x, y) ->
      @game.debug.pixel obj.x, obj.y
      @game.debug.object obj, x, y,
        color: "auto"
        label: obj.name
        keys: ["trackTarget", "trackTargetX", "trackTargetY"]
      return

    debugTrackingData: (obj, x, y) ->
      @game.debug.object obj.data, x, y,
        color: "auto"
        label: "#{obj.name}.data"
        sort: yes
      return
