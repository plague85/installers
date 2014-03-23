<?php
// This script will start multiple rtorrent sessions and shutdown each
// session before terminating.

// To use with cron:
// crontab -e
// */10 * * * *  /usr/bin/php ~/start_rtorrent.php cron

// If you have a functioning email, email will be sent to notify
// restarting of any rtorrent session only

// Start tmux server
exec("tmux start-server");

// set session name
$tmux_session = "rtorrent";

//check if session exists
$exec = exec("tmux list-session | grep $tmux_session", $session);
if (count($session) !== 0) {
	if (isset($argv[1]) && ($argv[1] === "kill" || $argv[1] === "exit")) {
		exec("tmux send-keys -t $tmux_session:0 C-q");
		exec("tmux send-keys -t $tmux_session:1 C-q");
		exec("tmux send-keys -t $tmux_session:2 C-q");
		exec("tmux send-keys -t $tmux_session:3 C-q");
		exec("tmux send-keys -t $tmux_session:4 C-q");
		$dead = false;
		echo "Waiting for rtorrent sessions to terminate.\n";
		while ($dead === false) {
			if (shell_exec("tmux list-panes -t${tmux_session}:0 | grep -c dead") == 1) {
				if (shell_exec("tmux list-panes -t${tmux_session}:1 | grep -c dead") == 1) {
					if (shell_exec("tmux list-panes -t${tmux_session}:2 | grep -c dead") == 1) {
						if (shell_exec("tmux list-panes -t${tmux_session}:3 | grep -c dead") == 1) {
							if (shell_exec("tmux list-panes -t${tmux_session}:4 | grep -c dead") == 1) {
								$dead = true;
							}
						}
					}
				}
			}
			sleep(10);
			echo ".";
		}
		echo "\nAll rtorrent sessions terminated.\n";
		if (isset($argv[1]) && $argv[1] === "exit") {
			echo "tmux session $tmux_session has been terminated.\n";
			exec("tmux kill-session -t $tmux_session");
		}
	} else {
		// restart rtorrent sessions if dead
		if (shell_exec("tmux list-panes -t${tmux_session}:0 | grep -c dead") == 1) {
			echo "$tmux_session:0 appears to be dead, restarting\n";
			exec("tmux respawnp -t $tmux_session:0 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent.rc'");
		}
		if (shell_exec("tmux list-panes -t${tmux_session}:1 | grep -c dead") == 1) {
			echo "$tmux_session:1 appears to be dead, restarting\n";
			exec("tmux respawnp -t $tmux_session:1 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-1.rc'");
		}
		if (shell_exec("tmux list-panes -t${tmux_session}:2 | grep -c dead") == 1) {
			echo "$tmux_session:2 appears to be dead, restarting\n";
			exec("tmux respawnp -t $tmux_session:2 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-2.rc'");
		}
		if (shell_exec("tmux list-panes -t${tmux_session}:3 | grep -c dead") == 1) {
			echo "$tmux_session:3 appears to be dead, restarting\n";
			exec("tmux respawnp -t $tmux_session:3 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-3.rc'");
		}
		if (shell_exec("tmux list-panes -t${tmux_session}:4 | grep -c dead") == 1) {
			echo "$tmux_session:4 appears to be dead, restarting\n";
			exec("tmux respawnp -t $tmux_session:4 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-4.rc'");
		}
		if (shell_exec("tmux list-panes -t${tmux_session}:8 | grep -c dead") == 1) {
			if ((isset($argv[1]) && $argv[1] !== 'cron') || !isset($argv[1])) {
				exec("tmux respawnp -t $tmux_session:8 'chromium-browser'");
			}
		}
		if ((isset($argv[1]) && $argv[1] !== 'cron') || !isset($argv[1])) {
			exec("tmux a -t $tmux_session");
		}
	}
} else {
	if (isset($argv[1]) && $argv[1] === "kill") {
		echo "There is no session to kill.\n";
		sleep(2);
	} elseif (isset($argv[1]) && $argv[1] === "exit") {
		echo "There is no session to exit.\n";
		sleep(2);
	}

	exec("tmux -f ~/.tmux.conf new-session -d -s $tmux_session -n rutorrent 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent.rc'");
	exec("tmux new-window -t $tmux_session:1 -n rutorrent-1 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-1.rc'");
	exec("tmux new-window -t $tmux_session:2 -n rutorrent-2 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-2.rc'");
	exec("tmux new-window -t $tmux_session:3 -n myananomouse-1 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-3.rc'");
	exec("tmux new-window -t $tmux_session:4 -n myananomouse-2 'rtorrent -n -o http_capath=~/certs -o import=~/.rtorrent-4.rc'");
	exec("tmux new-window -t $tmux_session:5 -n htop 'htop'");
	exec("tmux new-window -t $tmux_session:6 -n vnstat 'watch -n30 \"vnstat -u && vnstat -i eth0\"'");
	exec("tmux selectp -t 0; tmux splitw -t $tmux_session:6 -h -p 50 'vnstat -l'");
	exec("tmux new-window -t $tmux_session:7 -n bash 'bash -i'");
	exec("tmux new-window -t $tmux_session:8 -n chromium 'chromium-browser'");
	if ((isset($argv[1]) && $argv[1] !== 'cron') || !isset($argv[1])) {
		exec("tmux select-window -t $tmux_session:7; tmux attach-session -d -t $tmux_session");
	}
}
