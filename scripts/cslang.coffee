# Description:
#   Integrates Hubot with CloudSlang
#
# Dependencies:
#   None
#
# Configuration:
# HUBOT_OPENSTACK_HOST - hostname of your OpenStack environment
# HUBOT_OPENSTACK_USERNAME - username of your OpenStack environment
# HUBOT_OPENSTACK_PASSWORD - password of your OpenStack environment
# HUBOT_OPENSTACK_TENANT_NAME - tenant name of your Openstack environment - optional
# HUBOT_OPENSTACK_IMG_REF - server image reference for Openstack - optional
# HUBOT_DOCKER_HOST - hostname of your Docker machine
# HUBOT_DOCKER_USERNAME - username of your Docker machine
# HUBOT_DOCKER_PASSWORD - password of your Docker machine
# HUBOT_EMAIL_HOST - SMTP hostname for sending emails
# HUBOT_EMAIL_PORT - SMTP port
# HUBOT_EMAIL_USERNAME - Hubot's email address
# HUBOT_EMAIL_PASSWORD - Hubot's email password
#
# Commands:
#   hubot version - gets CloudSlang version
#   hubot say <phrase> - prints phrase to screen using print_text.sl operation
#   hubot send mail to <email> about <subject>.Details: <text> - sends email
#   hubot create openstack server <servername> - creates OpenStack server
#   hubot delete openstack server <servername> - deletes OpenStack server
#   hubot list openstack servers - prints OpenStack servers
#   hubot do openstack health check and send errors to <email> - creates Openstack server, checks that it is online and then deletes it, sending an email if any of the operations failed
#   hubot do docker demo and send errors to <email> - pulls mysql and a web application as Docker images and links them sending an email if any of the operations failed
#   hubot delete unused docker images if diskspace is greater than <percentage> - deletes all unused Docker images if diskspace is greater than the specified value
# Author:
#   tudorlesan

{spawn, exec}  = require 'child_process'
module.exports = (robot) ->
  openstack_host = process.env.HUBOT_OPENSTACK_HOST
  openstack_username = process.env.HUBOT_OPENSTACK_USERNAME
  openstack_password = process.env.HUBOT_OPENSTACK_PASSWORD

  process.env.HUBOT_OPENSTACK_IMG_REF ||= 'cfba3478-8645-4bc8-97e8-707b9f41b14e'
  process.env.HUBOT_OPENSTACK_TENANT_NAME ||= openstack_username
  openstack_tenant_name = process.env.HUBOT_OPENSTACK_TENANT_NAME
  openstack_img_ref = process.env.HUBOT_OPENSTACK_IMG_REF

  docker_host = process.env.HUBOT_DOCKER_HOST
  docker_username = process.env.HUBOT_DOCKER_USERNAME
  docker_password = process.env.HUBOT_DOCKER_PASSWORD
  email_host = process.env.HUBOT_EMAIL_HOST
  email_username = process.env.HUBOT_EMAIL_USERNAME
  email_password = process.env.HUBOT_EMAIL_PASSWORD
  email_port = process.env.HUBOT_EMAIL_PORT

  robot.catchAll (msg) ->
    if msg.message.text.indexOf("scorebot") == 0 or msg.message.text.indexOf("hubot") == 0
      msg.send "I don't know how to react to that (#{msg.message.text})"

  robot.on 'slave:command', (action, room) ->
    robot.messageRoom room, "#{action}"

  robot.on 'version', (room) ->
    robot.messageRoom room, 'Getting version...'

    slang = spawn 'cslang', ['version']
    slang.stderr.on 'data', (data) ->
      splitted = data.toString().split "\n"
      splitted = splitted[1].split ": "
      robot.messageRoom room, 'CloudSlang version: ' + splitted[1]

  robot.on 'create', (inputs, room) ->

    if openstack_host is undefined or openstack_username is undefined or openstack_password is undefined or openstack_img_ref is undefined or openstack_tenant_name is undefined
      robot.messageRoom room, "HUBOT_OPENSTACK_HOST, HUBOT_OPENSTACK_USERNAME, HUBOT_OPENSTACK_PASSWORD, HUBOT_OPENSTACK_IMG_REF have to be properly setup."

    else  
      split_inputs = inputs.split ","      
      server_input = split_inputs[0].split "="
      servername = server_input[1]
      robot.messageRoom room, "Creating server: " + servername

      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/openstack/create_openstack_server_flow.sl --i \"host=' + openstack_host + ',identity_port=5000,compute_port=8774,img_ref=' + openstack_img_ref + ',tenant_name=' + openstack_tenant_name + ',username=' + openstack_username + ',password=' + openstack_password + ',server_name=' + servername + '\"'
      slang = spawn 'cslang', [CLI_command]
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        robot.messageRoom room, splitted[0] 
        robot.messageRoom room, splitted[1] + ". Check execution.log for more details" if splitted[1] != ""  
  
  robot.on 'healthcheck', (inputs, room) ->

    if openstack_host is undefined or openstack_username is undefined or openstack_password is undefined or openstack_tenant_name is undefined or openstack_img_ref is undefined or email_host is undefined or email_port is undefined or email_username is undefined or email_password is undefined
      robot.messageRoom room, "HUBOT_OPENSTACK_HOST, HUBOT_OPENSTACK_USERNAME, HUBOT_OPENSTACK_PASSWORD, HUBOT_OPENSTACK_IMG_REF, HUBOT_EMAIL_HOST, HUBOT_EMAIL_PORT, HUBOT_EMAIL_USERNAME, HUBOT_EMAIL_PASSWORD have to be properly setup"

    else
      robot.messageRoom room, "Starting health check..."
      split_inputs = inputs.split ","
      email_input = split_inputs[0].split "="
      email = email_input[1]

      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/openstack/openstack_health_check.sl --i host=' + openstack_host + ',identity_port=5000,compute_port=8774,tenant_name=' + openstack_tenant_name + ',openstack_username=' + openstack_username + ',img_ref=' + openstack_img_ref + ',openstack_password=' + openstack_password + ',email_host=' + email_host + ',email_port=' + email_port + ',email_password=' + email_password + ',email_sender=' + email_username + ',email_recipient=' + email + ' --cp /home/hubot/Workspace/cloud-slang-content/content/io/cloudslang'

      slang = spawn 'cslang', [CLI_command]
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        robot.messageRoom room, splitted[0]
        robot.messageRoom room, splitted[1] + ". Check execution.log for more details." if splitted[1] != ""

  robot.on 'images', (inputs, room) ->
  
    if docker_host is undefined or docker_username is undefined or docker_password is undefined 
      robot.messageRoom room, "HUBOT_DOCKER_HOST, HUBOT_DOCKER_USERNAME, HUBOT_DOCKER_PASSWORD have to be properly setup"

    else
      robot.messageRoom room, "Deleting unused images..."
      split_inputs = inputs.split ","
      threshold_input = split_inputs[0].split "="
      threshold = threshold_input[1]
      percentage = threshold
      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/docker/maintenance/docker_images_maintenance.sl --i docker_host=' + docker_host + ',docker_username=' + docker_username + ',docker_password=' + docker_password + ',percentage=' + percentage + '% --cp /home/hubot/Workspace/cloud-slang-content/content/io/cloudslang'

      slang = spawn 'cslang', [CLI_command]
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        robot.messageRoom room, splitted[0]   

  robot.on 'demo', (inputs, room) ->

    if docker_host is undefined or docker_username is undefined or docker_password is undefined or email_host is undefined or email_port is undefined or email_username is undefined or email_password is undefined
      robot.messageRoom room, "HUBOT_DOCKER_HOST, HUBOT_DOCKER_USERNAME, HUBOT_DOCKER_PASSWORD, HUBOT_EMAIL_HOST, HUBOT_EMAIL_PORT, HUBOT_EMAIL_USERNAME, HUBOT_EMAIL_PASSWORD have to be properly setup"

    else
      robot.messageRoom room, "Starting docker demo..."
      split_inputs = inputs.split ","
      email_input = split_inputs[0].split "="
      recipient_email = email_input[1]

      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/docker/containers/demo_dev_ops.sl --i docker_host=' + docker_host + ',docker_username=' + docker_username + ',docker_password=' + docker_password + ',email_host=' + email_host + ',email_port=' + email_port + ',email_sender=' + email_username + ',email_password=' + email_password + ',email_recipient=' + recipient_email + ' --cp /home/hubot/Workspace/cloud-slang-content/content/io/cloudslang'
      slang = spawn 'cslang', [CLI_command]
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        robot.messageRoom room, splitted[0]   

  robot.respond /version/, (res) ->
    robot.emit 'version', res.message.user.room

  robot.respond /say (.*)/i, (msg) ->
    CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/base/print/print_text.sl --i \"text=' + msg.match[1] + '\"'

    slang = spawn 'cslang', [CLI_command]
    stream_iteration = 0
    slang.stdout.on 'data', (data) ->
      splitted = data.toString().split "\n"
      msg.send splitted[0] if stream_iteration == 0
      stream_iteration = stream_iteration + 1
    #slang.stderr.on 'data', (data) ->
      #msg.send data.toString()
  
  robot.respond /create openstack server (.*)/i, (res) -> 
    inputs = "servername=" + res.match[1]
    robot.emit 'create', inputs, res.message.user.room
    
  robot.respond /list openstack servers/i, (msg) -> 
    
    if openstack_host is undefined or openstack_username is undefined or openstack_password is undefined or openstack_tenant_name is undefined
      msg.send "HUBOT_OPENSTACK_HOST, HUBOT_OPENSTACK_USERNAME, HUBOT_OPENSTACK_PASSWORD have to be properly setup"

    else
      msg.send "Getting server list... "
      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/openstack/list_servers.sl --i host=' + openstack_host + ',identity_port=5000,compute_port=8774,tenant_name=' + openstack_tenant_name + ',username=' + openstack_username + ',password=' + openstack_password

      slang = spawn 'cslang', [CLI_command]
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        msg.send splitted[0]
        msg.send splitted[1] if splitted[1] != ""
      #msg.send splitted[1] + ". Check execution.log for more details." if splitted[1] != ""

  robot.respond /delete openstack server (.*)/i, (msg) -> 

    if openstack_host is undefined or openstack_username is undefined or openstack_password is undefined or openstack_tenant_name is undefined
      msg.send "HUBOT_OPENSTACK_HOST, HUBOT_OPENSTACK_USERNAME, HUBOT_OPENSTACK_PASSWORD have to be properly setup"

    else
      servername = msg.match[1]
      msg.send "Deleting server: " + servername
      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/openstack/delete_openstack_server_flow.sl --i \"host=' + openstack_host + ',identity_port=5000,compute_port=8774,tenant_name=' + openstack_tenant_name + ',username=' + openstack_username + ',password=' + openstack_password + ',server_name=' + servername + '\"'

      slang = spawn 'cslang', [CLI_command]
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        msg.send splitted[0] 
        msg.send splitted[1] + ". Check execution.log for more details." if splitted[1] != ""
  
  robot.respond /do openstack health check and send errors to ([-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4})/i, (msg) -> 
    inputs = "email=" + msg.match[1]
    robot.emit 'healthcheck', inputs, msg.message.user.room

  robot.respond /do docker demo and send errors to ([-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4})/i, (msg) -> 
    
    inputs = "email=" + msg.match[1]
    robot.emit 'demo', inputs, msg.message.user.room

  robot.respond /delete unused docker images if diskspace is greater than (\w+)/i, (msg) ->

    inputs = "threshold=" + msg.match[1]
    robot.emit 'images', inputs, msg.message.user.room

  robot.respond /send mail to ([-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4}) about (\w+).Details: (.*)/i, (msg) -> 

    if email_host is undefined or email_port is undefined or email_username is undefined or email_password is undefined
      msg.send "HUBOT_EMAIL_HOST, HUBOT_EMAIL_PORT, HUBOT_EMAIL_USERNAME, HUBOT_EMAIL_PASSWORD have to be properly setup"

    else
      receiver = msg.match[1]
      subject = msg.match[2]
      body = msg.match[3]
      msg.send "Sending mail to " + receiver + "..."

      CLI_command = 'run --f ~/Workspace/cloud-slang-content/content/io/cloudslang/base/mail/send_mail.sl --i \"from=' + email_username + ',to=' + receiver + ',hostname=' + email_host + ',port=' + email_port + ',subject=' + subject + ',body=' + body + ',username=' + email_username + ',password=' + email_password + '\"'
      slang = spawn 'cslang', [CLI_command]
    
      slang.stdout.on 'data', (data) ->
        splitted = data.toString().split "\n"
        msg.send splitted[0]

#/send mail from (\w+) to (\w+) about ([^.]*)
#^([a-zA-Z0-9]+[^a-zA-Z0-9]*){1,3}
#((\w+)\W+(\w+))
#scorebot scorebot send mail from a to b about that.Details: hello world 
#doing;hello again
