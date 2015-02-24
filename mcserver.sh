#!/bin/bash

ORIGIN_1_8_1='original_1.8.1/minecraft_server.1.8.1.jar'
DEFAULT_JAR=$ORIGIN_1_8_1
TMUX_NAME='MCServer_Tmux'
PID_FILE='/home/mcserver/tmuxpid_for_supervisord.pid'
WAIT_EXIT_TIMEOUT=10

test_run() {
  tmux has-session -t $TMUX_NAME
  # tmux 0 for find session, 1 for not find session
  # FIXME: don't know why redirect stderr cause stuck
  RETVAL="$?"
  if [ "$RETVAL" -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

start_from_path() {
  SERVER_FOLDER=/home/mcserver/minecraft/$(dirname "$1")
  JAR_NAME=$(basename "$1")
  WORK_CMD="java -Xmx2048M -jar $JAR_NAME nogui"

  # check if tmux is running 
  
  if ! test_run; then
    cd $SERVER_FOLDER
    echo "Change to folder $SERVER_FOLDER"
    echo "Start Minecraft Server in tmux session...."

    tmux new-session -d -s $TMUX_NAME -n $TMUX_NAME "$WORK_CMD" 
    # for debug
    # tmux send-keys -t $TMUX_NAME:$TMUX_NAME.0 "java -Xmx2048M -jar $JAR_NAME nogui"
    if [ "$?" -eq 0 ]; then 
      echo "Seesion --$TMUX_NAME-- deattached"
      # delete pidfile created last time then create it
      echo "Deleting pidfile $PID_FILE"
      rm -f $PID_FILE
      # FIXME: cannot get correct tmux session if already have an session before start
      # pid=$(pgrep -u mcserver -f "^tmux new-session -d -s $TMUX_NAME")
      pid=$(pgrep -u mcserver -f "$WORK_CMD")
      echo "Writing WORK_CMD pid $pid into $PID_FILE"
      echo $pid > $PID_FILE
      # TODO: make it as forever proxy and trap SIGNAL
    else
      echo "Error: exit with $? when tmux new-session"
    fi
  else
    echo "Error: tmux session $TMUX_NAME is already running"
  fi
}

stop_server() {
  #workaround for /root/tmux.config permission denied
  tmux send-keys -t $TMUX_NAME:$TMUX_NAME.0 'q' Enter
  tmux send-keys -t $TMUX_NAME:$TMUX_NAME.0 '/stop' Enter
}

case "$1" in
  start)
    shift
    if [ $# -eq 1 ]; then
    echo "Start MCServer in $1..."
    start_from_path $1
    else
      echo "Start MCServer in $DEFAULT_JAR (default)"
      start_from_path $DEFAULT_JAR
    fi
    ;;
  stop)
    echo "stopping server..."
    stop_server
    if [ $? -eq 0 ]; then
      echo "Sending shutdown to MCServer, waiting its quit..."
      sleep $WAIT_EXIT_TIMEOUT
      if test_run; then
	echo "Tmux still running, try to kill"
        kill -15 $(cat $PID_FILE)
      else
        echo "Tmux session closed."
      fi   
    else
      echo "Error: tmux send exit code $?"
    fi
    ;;
  status)
     if test_run; then
	echo "started"
     else
	echo "stopped"
     fi
     ;;
  test)
     test_run
     echo $?
     ;;
  poke)
     cur_time=$(date +%Y-%m-%d:%H:%M:%S)
     if ! test_run; then
       echo "[$cur_time $0] found mcserver tmux stopped, restarting"
       start_from_path $DEFAULT_JAR
     else
       echo "[$cur_time] regular check server status, running"
     fi
     ;;
  *)
     echo "usage: $0  status|stop|start [relative mc path to base]"
esac
