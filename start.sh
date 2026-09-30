#!/bin/sh

SERVERNAME="${SERVERNAME:-servertest}"
NOSTEAM="${NOSTEAM:-0}"
SERVER_DIR=/server
INI="/data/Server/${SERVERNAME}.ini"

cd "$SERVER_DIR" || exit 1

if [ -n "${MEMORY:-}" ]; then
    sed -i "s/\"-Xmx[^\"]*\"/\"-Xmx${MEMORY}\"/" ProjectZomboid64.json
fi

set -- -cachedir=/data -servername "$SERVERNAME"

case "$NOSTEAM" in
    1 | true) set -- "$@" -nosteam ;;
esac

if [ -n "${ADMINPASSWORD:-}" ]; then
    set -- "$@" -adminpassword "$ADMINPASSWORD"
fi

ini_value() {
    sed -n "s/^$1=//p" "$INI" 2>/dev/null | tr -d '\r'
}

shutdown() {
    password="$(ini_value RCONPassword)"
    if [ -n "$password" ]; then
        rcon-cli --host 127.0.0.1 --port "$(ini_value RCONPort)" --password "$password" quit
    else
        echo "RCONPassword is not set in $INI, stopping without saving" >&2
        kill -TERM "$pid"
    fi
}

trap shutdown TERM INT

export PATH="$SERVER_DIR/jre64/bin:$PATH"
export LD_LIBRARY_PATH="$SERVER_DIR/linux64:$SERVER_DIR:$SERVER_DIR/jre64/lib"
LD_PRELOAD="$SERVER_DIR/jre64/lib/libjsig.so" ./ProjectZomboid64 "$@" &
pid=$!

while :; do
    wait "$pid" && status=0 || status=$?
    kill -0 "$pid" 2>/dev/null || break
done

exit "$status"
