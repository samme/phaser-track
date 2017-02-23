Use
---

### Start tracking another object
```javascript
obj.track(target, offsetX = 0, offsetY = 0, trackRotation = false, rotateOffset = false, disableBodyMoves = true)
```

- `obj` is a [Sprite][1] or [Emitter][2]
- `target` is a Display Object, a [Pointer][3], or any object with `x` and `y`
- `trackRotation`: match the object's `rotation` to the target's
- `rotateOffset`: rotate the offset around the target by the target's `rotation`
- `disableBodyMoves`: suspend physics movement while tracking

An Emitter moves its launch point (`emitX`, `emitY`) to follow the target. A Sprite moves its `position`.

The object stops tracking only if

  - the target is destroyed; or
  - a Pointer target is deactivated; or
  - you call `untrack`

It doesn't stop tracking if the target is killed.

It will not track while its own `exists` is false.

### Stop tracking

```javascript
obj.untrack()
```

[1]: http://phaser.io/docs/2.6.2/Phaser.Sprite.html
[2]: http://phaser.io/docs/2.6.2/Phaser.Particles.Arcade.Emitter.html
[3]: http://phaser.io/docs/2.6.2/Phaser.Pointer.html