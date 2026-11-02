#!/bin/bash
#
# Starts httpd on 127.0.0.1:18080 and [::1]:18080 from the scratch copy of this folder, sends it 100 requests
# with curl (200, 206, 301, 304, 403, 404, 500 and CGI errors), and stops it.
#
#   run.sh <folder>      leaves <folder>/logs/access_log, error_log and answers
#
# The site is made here: a few pages, a forbidden folder, and CGI scripts that succeed, write no header, or
# exit with nothing.

set -euo pipefail
DIR=$1
cd "$DIR"

mkdir -p logs www/docs www/images www/private www/css cgi-bin
echo '<html><body>home</body></html>' > www/index.html
echo '<html>about</html>' > www/about.html
echo 'docs' > www/docs/index.html
echo 'body{}' > www/css/site.css
echo 'secret' > www/private/index.html
head -c 4000 /dev/zero | tr '\0' 'x' > www/images/big.txt
printf '#!/bin/sh\necho "Content-Type: text/plain"\necho\necho ok\necho "warning: cache cold for /reports" >&2\n' > cgi-bin/ok.cgi
printf '#!/bin/sh\necho "this is not a header"\n' > cgi-bin/broken.cgi
printf '#!/bin/sh\nexit 1\n' > cgi-bin/empty.cgi
chmod +x cgi-bin/*.cgi
sed "s|@DIR@|$DIR|g" httpd.conf.in > httpd.conf

/usr/sbin/httpd -f "$DIR/httpd.conf" -k start
trap '/usr/sbin/httpd -f "$DIR/httpd.conf" -k stop' EXIT   # stopped even if a step fails
sleep 1

V4=http://127.0.0.1:18080
V6='http://[::1]:18080'
AGENTS=("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
        "Googlebot/2.1 (+http://www.google.com/bot.html)"
        "check_http/v2.4 (monitoring-plugins)")
sent=0
# One request with the next user agent in turn, then a pause of 0.1 to 0.6 s so the times spread out.
request() {
    curl -g -s -o /dev/null -A "${AGENTS[$((sent % 4))]}" "$@" || true
    sleep "0.$((sent * 7 % 6 + 1))"
    sent=$((sent + 1))
}

for round in 1 2 3 4 5; do
    request "$V4/"
    request "$V4/about.html" -e https://www.example.com/
    request "$V4/css/site.css" -e "$V4/"
    request "$V4/missing.html"
    request "$V4/docs"                                          # 301 to /docs/
    request "$V4/docs/"
    request "$V4/images/"                                       # 403: no index, listings off
    request "$V4/private/"                                      # 403: denied
    request "$V4/cgi-bin/ok.cgi?report=$round"
    request "$V4/cgi-bin/broken.cgi"                            # 500: malformed header
    request "$V6/"
    request -I "$V4/index.html"
    request -H 'If-Modified-Since: Wed, 01 Jan 2031 00:00:00 GMT' "$V4/index.html"   # 304
    request -r 0-99 "$V4/images/big.txt"                        # 206
    request -X POST -d 'a=1' "$V4/about.html"
    request "$V4/cgi-bin/nothere.cgi"
    request "$V6/wp-login.php"
    request "$V4/cgi-bin/empty.cgi"                             # 500: no output
    request "$V4/search?q=log+parser&page=$round"
    request -u user-1042:hunter2 "$V4/about.html"
done

# Stop it here, and give it a moment to finish writing, rather than leaving that to the trap.
/usr/sbin/httpd -f "$DIR/httpd.conf" -k stop
trap - EXIT
sleep 2
