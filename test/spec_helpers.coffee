# test/spec_helpers.coffee

chai   = require 'chai'
expect = chai.expect


# helpers

host = 'http://localhost:3000'

newUsername = ->
  time = (new Date()).getTime()
  "player#{time}"


# methods

home = (callback) ->
  this.url host, (err) -> callback err


answerPopup = (answer, callback) ->
  id = if answer then '#popup-confirm' else '#popup-cancel'

  this
    .waitFor(id, 500)
    .pause(500)
    .click(id, (err) -> callback(err))

    # Selenium bug workaround
    # http://code.google.com/p/selenium/issues/detail?id=2766
    # .execute("setTimeout((function() {
    #   document.getElementById('#{id}').click();
    # }), 250);", (err) ->
    #   console.log "answerPopup callback\n#{err}")


newPlayer = (callback) ->
  username = newUsername()
  this.setValue '#username', username, (err) -> callback(err, username)


logout = (callback) ->
  this.url "#{host}/session/logout", (err) -> callback err


newGame = ({challenge}, callback=null) ->
  this
    .call(->
      if challenge?
        console.log 'challenge'
        # this.click(".player:contains(#{challenge})", (err) ->
        this.click(".player)", (err) ->
          expect(err).to.be.null
        )
      else
        this
          .pause(200)
          .buttonClick('#new-game', (err) ->
            expect(err).to.be.null
          )
    )
    .answerPopup true, (err) -> callback err


answerChallenge = (answer, callback) ->
  this.answerPopup(answer, (err) -> callback(err))

  # if answer
  #   driver.wait( ->
  #     driver.findElement id: 'popup-confirm'
  #   , 500)
  #   driver.executeScript "setTimeout((function() {
  #     document.getElementById('popup-confirm').click();
  #   }), 750);"


answerQuestions = ({all}, callback) ->
  this
    .pause(2000, ->
      this.getAttribute('.alternative:first', 'disabled', (err, res) ->
        this.execute("$('.alternative:first').click()")
      )
    )
    .call( ->
      if all
        this.url((err, res) ->
          if res.value.match /.*\/result/
            callback err
          else
            this.pause(250, -> this.answerQuestions all: true)
        )
    )
    .call callback


# export

commands = [
  { name: 'home',            fn: home }
  { name: 'answerPopup',     fn: answerPopup }
  { name: 'newPlayer',       fn: newPlayer }
  { name: 'logout',          fn: logout }
  { name: 'newGame',         fn: newGame }
  { name: 'answerChallenge', fn: answerChallenge }
  { name: 'answerQuestions', fn: answerQuestions }
]

module.exports.addCustomCommands = (browser) ->
  browser.addCommand(cmd.name, cmd.fn) for cmd in commands
