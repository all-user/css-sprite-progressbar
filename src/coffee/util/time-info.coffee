###*
* 安定したFPSを擬似的に表現するための時間に関する情報を提供するクラス<br>
* フレーム度に、前フレームからの経過時間を計測し実現したいFPSとの誤差を計算する
* @class TimeInfo
* @constructor
* `TimeInfo`のインスタンスを生成する
* @param {Number} goalFPS
###
class TimeInfo
  constructor: (goalFPS) ->
    @goalFPS = goalFPS
    @oldTime = 0
    @paused = yes
    @innerCount = 0
    @totalFPS = 0
    @totalCoefficient = 0

  ###* @method getInfo ###
  getInfo: (ts) ->
    if @paused is yes
      @paused = off
      @oldTime = ts || performance.now()
      return {
        elapsed: 0
        coefficient: 0
        FPS: 0
        averageFPS: 0
        averageCoefficient: 0
      }
    newTime = ts || performance.now()
    elapsed = newTime - @oldTime
    @oldTime = newTime
    FPS = 1000 / elapsed
    @innerCount++
    @totalFPS += FPS
    coefficient = @goalFPS / FPS
    @totalCoefficient += coefficient
    return {
      goalFPS:            @goalFPS
      elapsed:            elapsed
      coefficient:        coefficient
      totalCoefficient:   @totalCoefficient
      FPS:                FPS
      averageFPS:         @totalFPS         / @innerCount
      averageCoefficient: @totalCoefficient / @innerCount
    }

  ###* @method pause ###
  pause: ->
    @paused = on

module.exports = TimeInfo
