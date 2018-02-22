"use strict"

{Phaser} = this
{Point, Sprite} = Phaser
{Emitter} = Phaser.Particles.Arcade
{extend} = Phaser.Utils

_point = new Phaser.Point

_emitterDestroy = Emitter::destroy

Emitter::destroy = ->
  _emitterDestroy.call this
  if @data
    @data = {}
  return

getTrackTarget = ->
  @data.trackTarget

install = (obj) ->
  unless obj.postUpdate
    throw new Error "Object has no 'postUpdate' method"

  obj._trackComponentOrigPostUpdate = obj.postUpdate

  extend obj, trackComponent

  obj._setTrackUpdate()

  Object.defineProperty obj, "trackTarget",  get: getTrackTarget
  Object.defineProperty obj, "trackTargetX", get: obj._trackTargetX
  Object.defineProperty obj, "trackTargetY", get: obj._trackTargetY

  obj

trackComponent =

  postUpdate: ->
    # postUpdate is called even when `exists` is false
    result = @_trackComponentOrigPostUpdate.apply this, arguments

    unless @exists and @data
      return result

    target = @trackTarget

    unless target
      return result

    if target.pendingDelete or target.destroyPhase or target.game is null or target.active is no
      @untrack()
      return result

    {trackOffset, trackRotation, trackRotateOffset} = @data

    targetX = @_trackTargetX()
    targetY = @_trackTargetY()
    x = targetX + trackOffset.x
    y = targetY + trackOffset.y

    @_trackUpdate x, y, targetX, targetY, trackRotation, trackRotateOffset, target.worldRotation

    result

  _setTrackTargetGetters: (obj) ->
    switch
      when obj.worldX?
        @data.trackTargetGetX = @_trackTargetGetWorldX
        @data.trackTargetGetY = @_trackTargetGetWorldY
      when obj.world?
        @data.trackTargetGetX = @_trackTargetGetWorldPointX
        @data.trackTargetGetY = @_trackTargetGetWorldPointY
      when obj.position?
        @data.trackTargetGetX = @_trackTargetGetPositionX
        @data.trackTargetGetY = @_trackTargetGetPositionY
      else
        @data.trackTargetGetX = @_trackTargetGetX
        @data.trackTargetGetY = @_trackTargetGetY
    return

  _unsetTrackTargetGetters: ->
    @data.trackTargetGetX = null
    @data.trackTargetGetY = null
    return

  track: (obj, options = {}) ->
    # offsetX = 0, offsetY = 0, trackRotation = no, rotateOffset = no, disableBodyMoves = yes
    @data ?= {}
    @data.trackTarget       = obj
    @data.trackOffset      ?= new Point
    @data.trackOffset.x     = options.offsetX       or 0
    @data.trackOffset.y     = options.offsetY       or 0
    # @data.trackPosition     = options.trackPosition or null
    @data.trackRotation     = options.trackRotation or no
    @data.trackRotateOffset = options.rotateOffset  or no
    if @body and @body.moves and options.disableBodyMoves
      @body.moves = no
      @data.trackDisableBodyMoves = yes
    else
      @data.trackDisableBodyMoves = no
    @_setTrackTargetGetters obj
    return

  _trackTargetGetPositionX:   (target) -> target.position.x
  _trackTargetGetPositionY:   (target) -> target.position.y
  _trackTargetGetWorldPointX: (target) -> target.world.x
  _trackTargetGetWorldPointY: (target) -> target.world.y
  _trackTargetGetWorldX:      (target) -> target.worldX
  _trackTargetGetWorldY:      (target) -> target.worldY
  _trackTargetGetX:           (target) -> target.x
  _trackTargetGetY:           (target) -> target.y
  _trackTargetX:                       -> if @data.trackTarget then @data.trackTargetGetX(@data.trackTarget) else null
  _trackTargetY:                       -> if @data.trackTarget then @data.trackTargetGetY(@data.trackTarget) else null

  _trackUpdate: ->

  _setTrackUpdate: ->
    @_trackUpdate =
      if @constructor is Emitter
        @_trackUpdateEmitter
      else
        @_trackUpdateSprite
    return

  _trackUpdateEmitter: (x, y, targetX, targetY, trackRotation, rotateOffset, rotation) ->
    @emitX = x
    @emitY = y
    if trackRotation and rotation?
      # Probably not what you want!
      @rotation = rotation
    if rotateOffset and rotation?
      @_trackRotateEmit x, y, targetX, targetY, rotation
    return

  _trackRotateEmit: (x, y, targetX, targetY, rotation) ->
    _point
      .set x, y
      .rotate targetX, targetY, rotation
    @emitX = _point.x
    @emitY = _point.y
    return

  _trackUpdateSprite: (x, y, targetX, targetY, trackRotation, rotateOffset, rotation) ->
    @position.set x, y
    if trackRotation and rotation?
      @rotation = rotation
    if rotateOffset and rotation?
      @position.rotate targetX, targetY, rotation
    return

  untrack: ->
    @data.trackOffset.set 0
    @data.trackRotateOffset = null
    @data.trackRotation = null
    @data.trackTarget = null
    if @body and @data.trackDisableBodyMoves
      @body.moves = yes
    @data.trackDisableBodyMoves = null
    @_unsetTrackTargetGetters()
    return

install Emitter.prototype
install Sprite.prototype
