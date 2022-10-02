# Gmail Apple II Email Gateway

## Motivation

To connect an Apple II to Gmail, allowing messages to be sent and received.

I originally set up this gateway to use Ewen Wannop (aka Speccie)'s SAM2 email
client, running on the Apple IIgs under GSOS 6.0.4. Speccie's website is
[here](https://speccie.uk/software/)

The same gateway setup also works for my very own Emai//er suite for the
Apple //e and IIgs.  You can find Emai//er
[here](https://github.com/bobbimanners/emailler)

In order to communicate on today's Internet Transport Layer Security (TLS)
is necessary.  Retro machines such as the Apple II series lack the processor
power to perform the necessary encryption, so it is necessary to have a proxy
system in between the Apple II and Gmail's servers.  This proxy machine can
'speak' in today's encrypted TLS protocols to Gmail, and in plaintext to our
Apple II.  I chose to use a Raspberry Pi 4 (2GB version) running the Raspbian
Linux operating system version 10.

## Prerequisites

 - For Emai//er on the //e or GS:
   - An Apple //e enhanced or Apple IIgs system (ROM01 or ROM03)
   - At least 128KB of system memory.
   - Enough disk space.  I have a MicroDrive/Turbo with 32MB volumes.
   - Uthernet II ethernet card.  No other cards are supported.
   - ProDOS.  I am using version 2.4.2.
 - or, for SAM2 email on the GS:
   - An Apple IIgs.  Mine is a ROM01.
   - Enough memory  I have a 4MB RAM card.
   - Enough disk space.  I have a MicroDrive/Turbo with 32MB volumes.
   - A compatible ethernet card.  I used an Uthernet II.
   - GSOS 6.0.1 or 6.0.4 installed.
   - Marinetti 3.0 installed.  I used 3.0b11.
 - A Raspberry Pi running Raspbian 10

I don't cover any of the above in this README.  You can find information
[elsewhere](http://www.apple2.org/marinetti/) on how to set up Marinetti.

## Software Used

I use three separate packages on the Raspberry Pi, as follows:

 - *Postfix*  This is a full-featured mail tranfer agent.  We will use it
   to send mail to the Gmail servers over the SMTPS port with TLS, and to
   act as a plaintext SMTP server for the local network.
 - *Fetchmail*  Fetchmail is configured to pull down messages from a Gmail
   inbox and store it on the Raspberry Pi in `/var/mail/` using the IMAP
   protocol with TLS.
 - *Dovecot*  Dovecot provides a POP3 server to the local network, serving
   the files in `/var/mail`.

## Principle of Operation

### Incoming Messages

 - Message is sent to Gmail username@gmail.com
 - Fetchmail runs as a service on the Pi and monitors Gmail using IMAP
   IDLE.  As soon as a message shows up in the INBOX it downloads it
   and places it in `/var/mail/pi` (for username `pi`).  Fetchmail leaves
   the email on the Gmail server (this can be changed if desired.)
 - SAM2 mail client on the Apple IIgs is configured to use the IP
   of the Raspberry Pi as its POP3 email server.  When it asks for new
   messages, Dovecot will serve the request on port 110.  When messages are
   downloaded using POP3, they are deleted from `/var/mail/pi` on the
   Raspberry Pi.

### Outgoing Messages

 - The SAM2 mail client on the Apple IIgs is configured to use the IP of the 
   Raspberry Pi as its SMTP server.  Outgoing emails are sent to port 25
   on the Raspberry Pi.
 - Postfix handles the plaintext SMTP dialog with SAM2 mail and relays the
   message to Gmail's servers using SMTPS with TLS.

## Installing the Packages on Rasbian

Install the packages with root privs on the Pi:
```
sudo apt update
sudo apt upgrade
sudo apt install postfix postfix-pcre libsasl2-modules
sudo apt install dovecot-common dovecot-pop3d
sudo apt install fetchmail
```

## Obtaining App Passwords from Google

Google provides a mechanism to allow non-Google apps to connect to Gmail
called *App Passwords*.

Google's help page is [here](https://support.google.com/accounts/answer/185833?hl=en)

In order to use the App Passwords method of authentication 2-Step Verification
must be turned on for the account.  This is the general approach:

 - In a web browser log in to the Gmail account and go to
[Google Account](https://myaccount.google.com/).
 - In the panel on the left, choose *Security*.
 - Enable *2-Step Verification* for the account.
 - The option *App Passwords* will now appear. Select this option.
 - At the bottom, choose *Select app* and enter a descriptive name for
   the app.
 - Choose *Select Device* and choose the device.
 - Click *Generate*.
 - A 16 character App Password will be shown on the screen.  Write this value
   down because you will need it later in the configuration.

I generated two separate App Passwords - one for SMTPS and one for IMAPS.

## Configuring the Packages

### Postfix

The Postfix MTA configuration files are in `/etc/postfix`.  Of the three
packages, Postfix is the most complex to configure and has many available
options.

[This](https://www.linode.com/docs/email/postfix/postfix-smtp-debian7/)
page was helpful for configuring Postfix.

Be aware that this configuration amounts to an open relay from unsecured
SMTP to SMTPS, and must never be place on the public internet, or it will be
abused by spammers!  Keep it on your private LAN segment only!

We will modify a number of configuration files:

 - `/etc/postfix/command_filter`
 - `/etc/postfix/main.cf`
 - `/etc/postfix/master.cf`
 - `/etc/postfix/sasl/sasl_passwd`
 - `/etc/postfix/sasl/sasl_passwd.db`

Once Postfix has been configured, the service may be controlled as follows:
  - `systemctl start postfix` - start service.
  - `systemctl stop postfix` - stop service.
  - `systemctl status postfix` - status of service.

#### `command_filter`

For some reason, SAM2 sends a bunch of mail headers *after* the email message
has been tranmitted to Postfix's SMTP server.  Postfix gets very unhappy about
this.  The solution is to filter them out using Postfix's
`smtpd_command_filter` function.

The `command_filter` files contains the regular expressions to filter out these
unwanted headers:
```
/^Message-ID:.*$/ NOOP
/^MIME-version:.*$/ NOOP
/^Content-Type:.*$/ NOOP
/^Content-transfer-encoding:.*$/ NOOP
/^From:.*$/ NOOP
/^To:.*$/ NOOP
/^In-Reply-To:.*$/ NOOP
/^Subject:.*$/ NOOP
/^Date:.*$/ NOOP
/^X-Mailer:.*$/ NOOP
```

#### `main.cf`

This is the main Postfix configuration file.

I adjusted `smtpd_use_tls = no` to turn off TLS for the SMTP service offered to
the Apple II and added `smtpd_command_filter =
pcre:/etc/postfix/command_filter` to activate the filter discussed above.

`relayhost = [smtp.gmail.com]:587` will forward email to Gmail's SMTPS server.

I adjusted `smtpd_relay_restrictions = permit_mynetworks
permit_sasl_authenticated defer_unauth_destination` to allow network hosts
listed in `mynetworks` to relay messages to the `relayhost`.

My home network is 192.168.10.0/24, so I added it here:
`mynetworks = 192.168.10.0/24 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128`.
You should adjust this line to match your own LAN subnet.

I had an issue where the Pi was unable to connect to Google's SMTP server.
It turned out it was trying to use IPv6, so I forced IPv4 as follows:
`inet_protocols = ipv4`

Another user reported an issue which was solved by commenting out this line

`# smtpd_command_filter = pcre:/etc/postfix/command_filter`

Finally I added the following block of settings to enabled SASL authentication
when talking to Gmail:

```
# Enable SASL authentication
smtp_sasl_auth_enable = yes
# Disallow methods that allow anonymous authentication
smtp_sasl_security_options = noanonymous
# Location of sasl_passwd
smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd
# Enable STARTTLS encryption
smtp_tls_security_level = encrypt
# Location of CA certificates
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

```

The whole thing looks like this:


```
# See /usr/share/postfix/main.cf.dist for a commented, more complete version


# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP $mail_name (Raspbian)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=no
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.

relayhost = [smtp.gmail.com]:587
# smtpd_command_filter = pcre:/etc/postfix/command_filter
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
#smtpd_recipient_restrictions = permit_mynetworks
myhostname = raspberrypi.home
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $myhostname, raspberrypi, localhost.localdomain, , localhost
mynetworks = 192.168.10.0/24 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = ipv4

# Enable SASL authentication
smtp_sasl_auth_enable = yes
# Disallow methods that allow anonymous authentication
smtp_sasl_security_options = noanonymous
# Location of sasl_passwd
smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd
# Enable STARTTLS encryption
smtp_tls_security_level = encrypt
# Location of CA certificates
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

```

#### `master.cf`

`master.cf` does not need to be modified other than to enable `smtpd` by
uncommenting the following line:

```
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (no)    (never) (100)
# ==========================================================================
smtp      inet  n       -       y       -       -       smtpd

```

If you require verbose debugging information to get the SMTP connection
working, change the line as follows:

```
smtp      inet  n       -       y       -       -       smtpd y
```

#### `sasl/sasl_passwd` and `sasl/sasl_passwd.db`

Create the directory `/etc/postfix/sasl`.

Create the file `/etc/postfix/sasl/sasl_passwd` as follows:

```
[smtp.gmail.com]:587 username@gmail.com:xxxx xxxx xxxx xxxx
```

where `username` is your Gmail account name and `xxxx xxxx xxxx xxxx` is the
App Password Google gave you.

Run: `sudo postmap /etc/postfix/sasl/sasl_passwd` to build the hash file
`sasl_passwd.db`.

#### Restart Postfix

Be sure to restart Postfix after any configuration changes:
`sudo systemctl restart postfix`
 
### Dovecot

The Dovecot POP3 server configuration files are in `/etc/dovecot`. I had
to edit the following two files (starting from the default Raspbian package):

 - `/etc/dovecot/conf.d/10-auth.conf`
 - `/etc/dovecot/conf.d/10-master.conf`

Once Dovecot has been configured, the service may be controlled as follows:
  - `systemctl start dovecot` - start service.
  - `systemctl stop dovecot` - stop service.
  - `systemctl status dovecot` - status of service.

#### `10-auth.conf`

The only non-comment lines are as follows:
```
disable_plaintext_auth = no
auth_mechanisms = plain
!include auth-system.conf.ext
```

#### `10-master.conf`

I enabled the POP3 service on port 110 by uncommenting the `port = 110`
line as follows:

```
service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    #port = 995
    #ssl = yes
  }
}
```


### Fetchmail

Fetchmail's configuration is in the file `/etc/fetchmailrc`.  It should look
like this:

```
set postmaster "pi"
set bouncemail
set no spambounce
set softbounce
set properties ""
poll imap.gmail.com with proto IMAP auth password
       user 'username' is pi here
       password 'xxxx xxxx xxxx xxxx'
       ssl, sslcertck, idle

```

Replace the `xxxx xxxx xxxx xxxx` with the App Password Google gave you. 
Replace `username` with your email account name.

Make sure the permissions on the configuration file are okay:

```
chmod 600 /etc/fetchmailrc
chown fetchmail.root /etc/fetchmailrc
```

Edit `/etc/default/fetchmail` to enable the Fetchmail service:

```
START_DAEMON=yes
```

Service controls:
  - `systemctl start fetchmail` - start service.
  - `systemctl stop fetchmail` - stop service.
  - `systemctl status fetchmail` - status of service.


## Testing

Log messages from all these packages are written to `/var/log/mail.log`.

You can test the Postfix SMTP server using `telnet`.  Be aware that it may
not work the same way from the Pi (ie: localhost) than from a different
machine on your LAN, so it is better to connect from another host.

Connect to SMTP like this `telnet raspberrypi 25`.  Typing the following
commands should send an email:

```
HELO myhost.mydomain.com
MAIL FROM:<myaccount@mydomain.com>
RCPT TO:<someotheraccount@somedomain.com>
DATA
Subject: Test message
This is just
a simple test.
.
```

The final period on its own serves to terminate the message and signal to 
Postfix that it should process the DATA block and enqueue the message.

## What if you want multiple GMail accounts for multiple Apple IIs?

If, like me, you have more than one Apple II equipped with an Uthernet-II
card, you may find it convenient to have a separate GMail account associated
with each machine.

The basic idea here is to have two different GMail accounts, each associated
with a separate Linux user account on the Raspberry Pi.

These instructions assume you have already successfully configured one
GMail account to connect to the Apple II as described in this document.

 - Create a second GMail account, for example user2@gmail.com
 - Enable two-factor authentication for user2@gmail.com and obtain an app
   password.  Follow the instructions
   [here](#Obtaining-App-Passwords-from-Google)
 - Create a new Linux account, for example 'user2', on your Raspberry Pi.
   You may use the `useradd` command.  Fetchmail requires that each email
   account be associated with a Linux account.  Set a password for the
   new user account using `passwd` and make sure it has a valid home
   directory and that you are able to log in using the new account.

### Postfix Configuration for Multiple GMail accounts

The Postfix configuration documented above needs to be adjusted slightly
to allow mail to be sent to both GMail accounts.

The following files are affected:

  - `/etc/postfix/main.cf`
  - `/etc/postfix/sender_relay`
  - `/etc/postfix/sasl/sasl_passwd`

#### `main.cf`

Add the following lines to `/etc/postfix/main.cf`:

```
smtp_sender_dependent_authentication = yes
smtp_dependent_relayhost_maps = hash:/etc/postfix/sender_relay
```

#### `sender_relay`

You will have to create the file `/etc/postfix/sender_relay`, as follows:

```
user1@gmail.com    [smtp.gmail.com]:587
user2@gmail.com    [smtp.gmail.com]:587
```

Run: `sudo postmap /etc/postfix/sender_relay` to build the hash file
`sender_relay.db`.

#### `sasl_passwd`

Modify `/etc/postfix/sasl/sasl_passwd` as follows.

```
user1@gmail.com       user1@gmail.com:aaaa bbbb cccc dddd
user2@gmail.com       user2@gmail.com:eeee ffff gggg hhhh
[smtp.gmail.com]:587  user1@gmail.com:aaaa bbbb cccc dddd
```

This file records the Google App password for each of the GMail accounts.
The final line is a default entry, if nothing matches.

Run: `sudo postmap /etc/postfix/sasl/sasl_passwd` to build the hash file
`sasl_passwd.db`.

#### Restart Postfix

Be sure to restart Postfix after any configuration changes:
`sudo systemctl restart postfix`

### Fetchmail Configuration for Multiple GMail accounts

Edit `/etc/fetchmailrc` as follows:

```
set postmaster "pi"
set bouncemail
set no spambounce
set softbounce
set properties ""
poll imap.gmail.com with proto IMAP auth password
       user 'user1' is pi here
       password 'aaaa bbbb cccc dddd'
       ssl, sslcertck
       user 'user2' is user2 here
       password 'eeee ffff gggg hhhh`
       ssl, sslcertck
```

Fetchmail does not support IMAP idle when retrieving mail for more than
one account.

#### Restart Fetchmail

```
sudo systemctl restart fetchmail
```

Bobbi
Jun 3, 2021
*bobbi.8bit@gmail.com*


