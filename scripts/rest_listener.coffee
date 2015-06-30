# Description:
#
# Controls slave at event-slave.coffee
#
# Commands:
#
# hubot tell slave to <action> - Emits event to slave to do the action

module.exports = (robot) ->
   robot.router.post '/hubot/notify/:room', (req, res) ->
     room = req.params.room
     action = req.body.message
     robot.emit 'slave:command', action, room
     res.end()

   robot.router.get '/hubot/version/:room', (req, res) ->
     room = req.params.room
     robot.emit 'version', room
     res.end()

   robot.router.post '/hubot/create/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'create', inputs, room
     res.end()

   robot.router.post '/hubot/list/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'list', inputs, room
     res.end()

   robot.router.post '/hubot/delete/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'delete', inputs, room
     res.end()

   robot.router.post '/hubot/healthcheck/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'healthcheck', inputs, room
     res.end()

   robot.router.post '/hubot/demo/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'demo', inputs, room
     res.end()
   
   robot.router.post '/hubot/images/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'images', inputs, room
     res.end()

   robot.router.post '/hubot/email/:room', (req, res) ->
     room = req.params.room
     inputs = req.body.message
     robot.emit 'email', inputs, room
     res.end()




