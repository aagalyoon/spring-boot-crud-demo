#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_dir="$project_dir/.demo"
pid_file="$runtime_dir/server.pid"
log_file="$runtime_dir/server.log"
jar_file="$project_dir/target/spring-items-service-1.0.0.jar"
job_label="com.agalyoon.tcs.spring-items-demo"

running_pid() {
  local pid command_line job_state
  job_state="$(launchctl list "$job_label" 2>/dev/null)" || return 1
  pid="$(printf '%s\n' "$job_state" | sed -n 's/.*"PID" = \([0-9][0-9]*\);.*/\1/p' | head -1)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  [[ "$command_line" == *" -jar $jar_file"* ]] || return 1
  printf '%s\n' "$pid"
}

stop_demo() {
  local pid
  if ! launchctl list "$job_label" >/dev/null 2>&1; then
    [[ ! -f "$pid_file" ]] || rm "$pid_file"
    echo "Items API is stopped."
    return
  fi
  pid="$(running_pid || true)"
  launchctl remove "$job_label"
  for _ in {1..50}; do
    if ! launchctl list "$job_label" >/dev/null 2>&1 && { [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; }; then
      [[ ! -f "$pid_file" ]] || rm "$pid_file"
      echo "Items API stopped."
      return
    fi
    sleep 0.1
  done
  echo "Items API did not stop; check job $job_label and PID $pid." >&2
  return 1
}

case "${1:-}" in
  start)
    if pid="$(running_pid)"; then
      echo "Items API is already running at http://localhost:8080 (PID $pid)."
      exit 0
    fi
    if launchctl list "$job_label" >/dev/null 2>&1; then
      launchctl remove "$job_label"
    fi
    if [[ -n "$(lsof -nP -iTCP:8080 -sTCP:LISTEN -t 2>/dev/null || true)" ]]; then
      echo "Port 8080 is in use by another process. Stop it before starting this demo." >&2
      exit 1
    fi
    if [[ -z "${JAVA_HOME:-}" && -x /opt/homebrew/opt/openjdk@17/bin/java ]]; then
      export JAVA_HOME=/opt/homebrew/opt/openjdk@17
    fi
    if [[ -n "${JAVA_HOME:-}" ]]; then
      java_bin="$JAVA_HOME/bin/java"
    else
      java_bin="$(command -v java)"
    fi
    mkdir -p "$runtime_dir"
    (cd "$project_dir" && mvn -q -DskipTests package)
    launchctl submit -l "$job_label" -o "$log_file" -e "$log_file" -- "$java_bin" -jar "$jar_file"
    for _ in {1..80}; do
      if pid="$(running_pid)" && curl --silent --fail --max-time 1 -o /dev/null http://localhost:8080/items; then
        printf '%s\n' "$pid" >"$pid_file"
        echo "Items API ready at http://localhost:8080 (PID $pid)."
        exit 0
      fi
      sleep 0.25
    done
    echo "Items API did not start. See $log_file." >&2
    exit 1
    ;;
  stop)
    stop_demo
    ;;
  status)
    if pid="$(running_pid)"; then
      echo "Items API is running at http://localhost:8080 (PID $pid)."
    else
      echo "Items API is stopped."
    fi
    ;;
  clean)
    stop_demo
    if [[ -d "$project_dir/target" ]]; then
      rm -r "$project_dir/target"
    fi
    if [[ -d "$runtime_dir" ]]; then
      rm -r "$runtime_dir"
    fi
    echo "Demo runtime and build files removed. Delete this folder when finished."
    ;;
  *)
    echo "Usage: $0 {start|stop|status|clean}" >&2
    exit 2
    ;;
esac
