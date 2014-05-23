# app/client/highscore/highscore.coffee

# helpers

Template.highscores.helpers
  highscores: ->
    Highscores.find(
      { score: { $gt: 0 } },
      { sort: { score: -1 } }
    ).fetch()

UI.registerHelper 'playerUsername', (playerId) ->
  player = Meteor.users.findOne(playerId)
  if player then player.profile.name else '?'

UI.registerHelper 'withPosition', (context, options) ->
  result = []
  for element, i in context
    element.position = i+1
    result.push element
  return result
