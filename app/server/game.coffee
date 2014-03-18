# app/server/game.coffee

# methods

Meteor.methods
  keepalive: (playerId) ->
    # check playerId
    return unless playerId

    Meteor.users.update playerId,
      $set:
        online: true
        lastKeepalive: (new Date()).getTime()


  newPlayer: (name) ->
    unless name
      throw new Meteor.Error 409, 'Username not set'
    # username taken
    else if Meteor.users.find( username: name ).count() > 0
      throw new Meteor.Error 409, 'Username taken'

    id = Meteor.users.insert { username: name }

    Meteor.users.update id,
      $set:
        'profile.online': true
        'profile.highscoreIds': []

    id


  newGame: (playerId, {challengeeId, acceptChallengeId}) ->
    # cannot challenge and answer challenge at same time
    if challengeeId and acceptChallengeId
      throw new Meteor.Error

    # if accepting challenge, find the game
    if acceptChallengeId
      gameId = Challenges.findOne(acceptChallengeId).challengeeGameId
    # else, create new game
    else
      # TODO: avoid getting the same questions
      questions = Questions.find({}, { limit: 5 }).fetch()

      gameId = Games.insert
        questionIds: questions.map (q) -> q._id
        pointsPerQuestion: CONFIG.POINTS_PER_QUESTION
        state: 'init'
        currentQuestion: 0
        answers: []

      challengeId = acceptChallengeId

    # if challenging, create new game for challengee
    if challengeeId
      # TODO: avoid getting the same questions
      challengeQuestions = Questions.find({}, { limit: 5 }).fetch()

      challengeeGameId = Games.insert
        questionIds: challengeQuestions.map (q) -> q._id
        pointsPerQuestion: CONFIG.POINTS_PER_QUESTION
        state: 'init'
        currentQuestion: 0
        answers: []

      challengeId = Challenges.insert
        challengerId: playerId
        challengeeId: challengeeId
        challengerGameId: gameId
        challengeeGameId: challengeeGameId

    # set users gameId and return it, together with challenge id
    Meteor.users.update playerId, $set: { 'profile.gameId': gameId }
    {
      gameId:      gameId
      challengeId: challengeId
    }

  endGame: (playerId) ->
    player = Meteor.users.findOne playerId
    game = Games.findOne player.profile.gameId

    # calculate score
    score = 0
    correctAnswers = 0
    for a in game.answers
      q = Questions.findOne a.questionId
      if a.answer is q.correctAnswer
        correctAnswers++
        score += a.points

    # update highscore
    highscoreId = Highscores.insert
      gameId: game._id
      playerId: playerId
      correctAnswers: correctAnswers
      score: score

    # mark game as finished
    Games.update game._id, { $set: { state: 'finished' } }

    # set game id
    Meteor.users.update playerId,
      $set: { 'profile.gameId': undefined }
      $addToSet: { 'profile.highscoreIds': highscoreId }
