timeInfo = (goalFPS) ->
  oldTime = 0
  paused = on
  interCount = 0
  totalFPS = 0
  totalCoefficient = 0

  getInfo: () ->
    if paused is on
      paused = off
      oldTime = Date.now()
      return {
        elapsed: 0
        coefficient: 0
        FPS: 0
        averageFPS: 0
        averageCoefficient: 0
      }

    newTime = Date.now()
    elapsed = newTime - oldTime
    oldTime = newTime
    FPS = 1000 / elapsed
    interCount++
    totalFPS += FPS
    coefficient = goalFPS / FPS
    totalCoefficient += coefficient

    elapsed: elapsed
    coefficient: coefficient
    FPS: FPS
    averageFPS: totalFPS / interCount
    averageCoefficient: totalCoefficient / interCount

  pause: ->
    paused = on

module.exports = timeInfo
