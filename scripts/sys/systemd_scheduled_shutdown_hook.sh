#!/bin/bash
# I remember watching a file in python was easy enough,
# but everything I found now involves watchdog, and
# looks too complex for this simple thing.

# env: CHATIDS: tg chat id(s)
# env: SSHHOSTS: ssh user@host
# env: TELEGRAM_BOT_TOKEN

# SSH: assuming ssh keys are available. DO restrict the system user you hopefully created.
# export user=otherhost_shutdown_hook && sudo adduser --system --shell /usr/local/bin/lish --disabled-password --disabled-login $user && git clone https://github.com/jschauma/lish.git && cd lish && sudo make install && cd .. && rm -rf lish && sudo mkdir /etc/lish && echo 'sudo /sbin/shutdown now' | sudo tee /etc/lish/$user && sudo mkdir "/home/$user/.ssh" && vim "/home/$user/.ssh/authorized_keys" && chmod 700 "/home/$user/.ssh" && chmod 600 "/home/$user/.ssh/authorized_keys"
# visudo: otherhost_shutdown_hook ALL= NOPASSWD: /sbin/shutdown
# 


dir="/run/systemd/shutdown"
file="scheduled"

# and no, this is not a hook! _everything is a file_
inotifywait --quiet --monitor --event moved_to,delete \
--format '%f,%e' "$dir" |\
while IFS=, read -r eventfile event; do
    if [[ "${eventfile}" == "${file}" ]]; then
        case "${event}" in
                MOVED_TO)
                    mode="$(sed -n 's/^MODE=\(.*\)/\1/p' < "${dir}/${file}")"
                    epoch="$(sed -n 's/^USEC=\(.*\)/\1/p' < "${dir}/${file}" | cut -c -10)"
                    epoch_date="$(date --utc --date="@${epoch}" --iso-8601=seconds)"
                    cur_epoch="$(date +%s)"
                    epoch_seconds_left="$(( epoch - cur_epoch ))"
                    msg=": ${mode} in ${epoch_seconds_left}s, ${epoch_date}; Shutdown initiated on ${SSHHOSTS}"

                    for ssh_host in ${SSHHOSTS}; do
                        ssh "${ssh_host}" sudo /sbin/shutdown now
                    done
                    ;;
                DELETE)
                    unset msg_raw
                    ;;
        esac
        for chatid in ${CHATIDS}; do
	    curl -X POST -H 'Content-Type: application/json' -d "{\"chat_id\": \"${chatid}\", \"text\": \"$(hostname) scheduled shutdown ${event}${msg}\"}" https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage
	    curl -X POST -H 'Content-Type: application/json' -d "{\"chat_id\": \"${chatid}\", \"text\": \"$(curl  -m10 https://7xx.arti.ee/plain)\", \"disable_notification\": true}" https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage &
        done
    fi
done
